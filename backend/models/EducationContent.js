import mongoose from 'mongoose';

/**
 * Education Content Model
 * Nutrition and fitness education articles/videos
 */
const educationContentSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true
  },
  content: {
    type: String,
    required: true
  },
  excerpt: String,
  type: {
    type: String,
    enum: ['article', 'video', 'infographic', 'guide', 'tip'],
    required: true
  },
  category: {
    type: String,
    enum: ['nutrition', 'fitness', 'wellness', 'recipes', 'science', 'tips'],
    required: true,
    index: true
  },
  tags: [String],
  imageUrl: String,
  videoUrl: String,
  duration: Number, // minutes for videos/articles
  difficulty: {
    type: String,
    enum: ['beginner', 'intermediate', 'advanced']
  },
  author: String,
  publishedDate: {
    type: Date,
    default: Date.now
  },
  views: {
    type: Number,
    default: 0
  },
  likes: {
    type: Number,
    default: 0
  },
  isFeatured: {
    type: Boolean,
    default: false,
    index: true
  },
  isPublished: {
    type: Boolean,
    default: true,
    index: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

educationContentSchema.index({ category: 1, publishedDate: -1 });
educationContentSchema.index({ isFeatured: 1, publishedDate: -1 });
educationContentSchema.index({ tags: 1 });

export default mongoose.model('EducationContent', educationContentSchema);


