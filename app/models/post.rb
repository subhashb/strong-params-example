class Post
  include Mongoid::Document
  field :title, type: String
  field :body, type: String
  field :published, type: Boolean

  belongs_to :created_by, class_name: 'User'
end
