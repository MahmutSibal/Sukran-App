using MongoDB.Driver.GeoJsonObjectModel;

namespace AppSukran.Domain.Common;

public sealed class GeoPoint
{
    public GeoJsonPoint<GeoJson2DGeographicCoordinates> Value { get; set; } = new(new GeoJson2DGeographicCoordinates(0, 0));

    public static GeoPoint FromCoordinates(double longitude, double latitude)
        => new()
        {
            Value = new GeoJsonPoint<GeoJson2DGeographicCoordinates>(new GeoJson2DGeographicCoordinates(longitude, latitude))
        };

    public double Longitude => Value.Coordinates.Longitude;
    public double Latitude => Value.Coordinates.Latitude;
}