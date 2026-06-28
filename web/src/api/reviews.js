// Değerlendirme/yorum uç noktaları (/api/reviews).
import { api } from './http';

export const getReviewsByRestaurant = (restaurantId) =>
  api.get(`/api/reviews/restaurant/${restaurantId}`, { auth: false });

export const getMyReviews = () => api.get('/api/reviews/me');

// payload: { restaurantId, comment, rating }
export const createReview = (payload) => api.post('/api/reviews', payload);

export const reactToReview = (reviewId, isLike) =>
  api.post(`/api/reviews/${reviewId}/react`, { isLike });

export const deleteReview = (reviewId) => api.del(`/api/reviews/${reviewId}`);

// payload: { comment, mentionedUserName? }
export const addReviewReply = (reviewId, payload) =>
  api.post(`/api/reviews/${reviewId}/replies`, payload);

export const deleteReviewReply = (reviewId, replyId) =>
  api.del(`/api/reviews/${reviewId}/replies/${replyId}`);
