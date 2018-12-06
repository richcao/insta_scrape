class InstaScrape::InstagramUserWithPosts
  attr_accessor :username, :image, :post_count, :follower_count, :following_count, :description, :posts, :profile_link
  def initialize(username, image, post_count, follower_count, following_count, description, profile_link, posts)
    @username = username
    @image = image
    @post_count = post_count
    @follower_count = follower_count
    @following_count = following_count
    @description = description
    @posts = posts
    @profile_link = profile_link
  end
end
