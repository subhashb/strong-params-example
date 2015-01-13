class CreatePost
  include ServiceObject

  attribute :post
  attribute :current_user
  attribute :params

  validates_presence_of :post, :current_user, :params

  def call
    post.attributes = params if params
    post.created_by = current_user
    fail!(post.errors) unless post.save
    
    post
  end

end
