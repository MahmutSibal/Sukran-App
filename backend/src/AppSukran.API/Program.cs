using System.Text;
using AppSukran.API.Middleware;
using AppSukran.Application;
using AppSukran.Infrastructure;
using AppSukran.Infrastructure.Realtime;
using AppSukran.Infrastructure.Settings;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration);
// NOT: Enum'lar bilerek SAYISAL (int) serialize edilir. Hem Flutter mobil hem
// Next.js web paneli yanıtlardaki enum'ları sayısal olarak okuyacak biçimde yazıldı;
// string'e çevirmek web panelini (numerik karşılaştırmalar) bozar. Girişte ise
// System.Text.Json zaten hem int hem string deseralize eder.
builder.Services.AddControllers();
builder.Services.AddSignalR();
builder.Services.AddHttpContextAccessor();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

const string WebClientCorsPolicy = "WebClient";
var configuredOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>()
    ?? new[] { "http://localhost:3000", "https://localhost:3000" };

builder.Services.AddCors(options =>
{
    options.AddPolicy(WebClientCorsPolicy, policy =>
    {
        if (builder.Environment.IsDevelopment())
        {
            policy.SetIsOriginAllowed(_ => true)
                .AllowAnyHeader()
                .AllowAnyMethod()
                .AllowCredentials();
        }
        else
        {
            // In production: only allow credentials when explicit, non-wildcard origins are configured.
            var hasWildcard = configuredOrigins?.Contains("*") ?? false;
            var hasOrigins = configuredOrigins != null && configuredOrigins.Length > 0;

            if (hasOrigins)
            {
                var corsBuilder = policy.WithOrigins(configuredOrigins!)
                    .AllowAnyHeader()
                    .AllowAnyMethod();

                if (!hasWildcard)
                {
                    corsBuilder.AllowCredentials();
                }
            }
            else
            {
                policy.AllowAnyHeader().AllowAnyMethod();
            }
        }
    });
});
builder.Services.AddRateLimiter(options =>
{
    options.AddFixedWindowLimiter("orders-write", limiterOptions =>
    {
        limiterOptions.PermitLimit = 30;
        limiterOptions.Window = TimeSpan.FromMinutes(1);
        limiterOptions.QueueLimit = 10;
        limiterOptions.AutoReplenishment = true;
    });

    options.AddFixedWindowLimiter("payments-write", limiterOptions =>
    {
        limiterOptions.PermitLimit = 20;
        limiterOptions.Window = TimeSpan.FromMinutes(1);
        limiterOptions.QueueLimit = 10;
        limiterOptions.AutoReplenishment = true;
    });

    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
});

var jwtSettings = builder.Configuration.GetSection("Jwt").Get<JwtSettings>() ?? new JwtSettings();
// Allow overriding the signing key from an environment variable for secret management workflows
var envSigningKey = Environment.GetEnvironmentVariable("JWT_SIGNING_KEY");
if (!string.IsNullOrEmpty(envSigningKey))
{
    jwtSettings.SigningKey = envSigningKey;
}
var signingKey = Encoding.UTF8.GetBytes(jwtSettings.SigningKey ?? string.Empty);

// Production'da zayıf/varsayılan imza anahtarıyla başlamayı engelle (fail-fast).
if (!builder.Environment.IsDevelopment())
{
    const string DevDefaultKey = "THIS_IS_A_DEVELOPMENT_ONLY_SIGNING_KEY_CHANGE_ME";
    if (string.IsNullOrWhiteSpace(jwtSettings.SigningKey) ||
        string.Equals(jwtSettings.SigningKey, DevDefaultKey, StringComparison.Ordinal) ||
        signingKey.Length < 32)
    {
        throw new InvalidOperationException(
            "JWT signing key is not configured for production. Set a strong (>=32 chars) JWT_SIGNING_KEY environment variable.");
    }
}

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
}).AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateIssuerSigningKey = true,
        ValidateLifetime = true,
        ValidIssuer = jwtSettings.Issuer,
        ValidAudience = jwtSettings.Audience,
        IssuerSigningKey = new SymmetricSecurityKey(signingKey),
        ClockSkew = TimeSpan.Zero
    };
});

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("SuperAdminOnly", policy => policy.RequireRole("SuperAdmin"));
});

builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;

    if (builder.Environment.IsDevelopment())
    {
        options.KnownIPNetworks.Clear();
        options.KnownProxies.Clear();
        options.ForwardLimit = 1;
    }
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseForwardedHeaders();
app.UseMiddleware<GlobalExceptionMiddleware>();

var httpsPortConfigured = !string.IsNullOrWhiteSpace(builder.Configuration["ASPNETCORE_HTTPS_PORT"]);
if (httpsPortConfigured)
{
    app.UseHttpsRedirection();
}

app.UseCors(WebClientCorsPolicy);
app.UseRateLimiter();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHub<OrderHub>("/hubs/orders");

app.Run();
