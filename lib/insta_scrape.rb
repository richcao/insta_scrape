require "dependencies"

module InstaScrape
  extend Capybara::DSL

  #get a hashtag
  def self.hashtag(hashtag, include_meta_data: false)
    visit "https://www.instagram.com/explore/tags/#{hashtag}/"
    scrape_posts(include_meta_data: include_meta_data) { |p| yield p }
  end

  #long scrape a hashtag
  def self.long_scrape_hashtag(hashtag, scrape_length, include_meta_data: false)
    visit "https://www.instagram.com/explore/tags/#{hashtag}/"
    long_scrape_posts(scrape_length, include_meta_data: include_meta_data) { |p| yield p }
  end

  #long scrape a hashtag
  def self.long_scrape_user_posts(username, scrape_length, include_meta_data: false)
    long_scrape_user_posts_method(username, scrape_length, include_meta_data: include_meta_data) { |p| yield p }
  end

  #get user info and posts
  def self.long_scrape_user_info_and_posts(username, scrape_length, include_meta_data: false)
    image, post_count, follower_count, following_count, description, profile_link = scrape_user_info(username)
    posts = []
		long_scrape_user_posts_method(username, scrape_length, include_meta_data: include_meta_data) { |p| posts << p }
    InstaScrape::InstagramUserWithPosts.new(username, image, post_count, follower_count, following_count, description, profile_link, posts)
  end

  #get user info
  def self.user_info(username)
    image, post_count, follower_count, following_count, description, profile_link = scrape_user_info(username)
    InstaScrape::InstagramUser.new(username, image, post_count, follower_count, following_count, description, profile_link)
  end

  #get user info and posts
  def self.user_info_and_posts(username, include_meta_data: false)
    image, post_count, follower_count, following_count, description, profile_link = scrape_user_info(username)

		posts = []
    scrape_user_posts(username, include_meta_data: false) { |p| posts << p }
    InstaScrape::InstagramUserWithPosts.new(username, image, post_count, follower_count, following_count, description, profile_link, posts)
  end

  #get user posts only
  def self.user_posts(username, include_meta_data: false)
    scrape_user_posts(username, include_meta_data: include_meta_data)
  end

  private
  #post iteration method


  def self.extract_post_metadata(url)
      visit(url)
      username = page.first("article header h2 > a")["title"]
      hi_res_image = page.all("img").last["src"]
      location = nil
      begin
        location = page.find("#react-root > section > main > div > div > article > header > div.o-MQd > div.M30cS > a")["innerHTML"]
      rescue Capybara::ElementNotFound => e
      end

      return username, location
  end

  def self.iterate_through_posts(include_meta_data:)
    posts = all("article div div div a").collect do |post|
      { link: post["href"],
        image: post.find("img")["src"],
        text: post.find("img")["alt"]}
    end
		puts "iterate_through_posts: #{posts.size} maximum"

    posts.each do |post|
      yield InstaScrape::InstagramPost.new(post[:link], post[:image], { text: text })
#			if ScrapeLog.exists?(url: url) then
#				puts "Already scraped #{url}"
#				next
#			else
#				puts "Scraping #{url}"
#			end
#			tries = 0
#			begin
#				if include_meta_data
#					visit(post[:link])
#					puts "Visiting.. #{post[:link]}"
#					date = page.find('time')["datetime"]
#					username = page.first("article header h2 > a")["title"]
#					hi_res_image = page.all("img").last["src"]
#					#location = page.find(:xpath, "//article/header/div[2]/div[2]/a")["innerHTML"]
#					location = nil
#					#location = page.find(:xpath, "/")	o
#					begin
#						location = page.find("#react-root > section > main > div > div > article > header > div.o-MQd > div.M30cS > a")["innerHTML"]
#					rescue Capybara::ElementNotFound => e
#					end
#					#location = page.find(:xpath, "article/header")
#
#					#likes = page.find("div section span span")["innerHTML"]
#					likes = nil
#					info = InstaScrape::InstagramPost.new(post[:link], post[:image], {
#						date: date,
#						text: post[:text],
#						username: username,
#						hi_res_image: hi_res_image,
#						likes: likes, 
#						location: location,
#					})
#				else
#					info = InstaScrape::InstagramPost.new(post[:link], post[:image], { text: text })
#				end
#				yield info
#				#output_posts << info
#				ScrapeLog.create(url: url, scraped_at: Time.current)
#
#			rescue => e
#				"Found an error.. retrying #{tries}"
#				tries += 1
#				retry if tries < 3
#			end
    end
  end

  #user info scraper method
  def self.scrape_user_info(username)
    visit "https://www.instagram.com/#{username}/"

    image = nil
		post_count = nil
		follower_count = nil
		following_count = nil
		description = nil
		profile_link = nil

    within("header") do
      items = page.find("ul").all("li")
			begin
				post_count = human_to_number items[0].find("span")['innerHTML']
				follower_count = human_to_number items[1].find("span")['innerHTML']
				following_count = human_to_number items[2].find("span")['innerHTML']

				description = page.find(:xpath, 'section/div[2]/span')['innerHTML']
				document = Nokogiri::HTML(description)
				document.css("br").each { |node| node.replace("\n") }

				description = document.text
				profile_link = page.find(:xpath, 'section/div[2]/a')['innerHTML'] 
			rescue Capybara::ElementNotFound => e
			end
    end
    return image, post_count, follower_count, following_count, description, profile_link
  end

  MULTIPLIERS = { 'k' => 10**3, 'm' => 10**6, 'b' => 10**9 }
  # convert 1.32K to 13200 or 1,175 to 1175.
  def self.human_to_number(human)
		human = human.delete(",")
		number = human[/(\d+\.?)+/].to_f
		factor = human[/\w$/].try(:downcase)
		(number * MULTIPLIERS.fetch(factor, 1)).to_i
  end

  #scrape posts
  def self.scrape_posts(include_meta_data:)
    #page.find('a', :text => "Load more", exact: true).click
    max_iteration = 10
    iteration = 0
    while iteration < max_iteration do
      iteration += 1
      page.execute_script "window.scrollTo(0,document.body.scrollHeight);"


      sleep 0.1
    end

		tries = 0
    begin
      iterate_through_posts(include_meta_data: include_meta_data) do |p| yield p end

    rescue Capybara::ElementNotFound => e
      puts "Retrying... "
			tries += 1
			retry if tries < 3
    end
  end

  def self.long_scrape_posts(max_iteration, include_meta_data:)
    #page.find('a', :text => "Load more", exact: true).click
    iteration = 0
    print "InstaScrape is working. Please wait."
    cache = Set.new

    # instagram randomly removes items everytime we scroll. so we read everything and filter out duplicates
    while iteration < max_iteration do
      iteration += 1
      sleep 0.1
      page.execute_script "window.scrollTo(0,document.body.scrollHeight);"

#      if (page.driver.console_messages.length > 0) then
#        page.driver.console_messages.each { |error| puts error }
#        raise "Javascript error."
#      end 

      sleep 1
      print "."
      begin
        iterate_through_posts(include_meta_data: include_meta_data) do |p| 
          yield p unless cache.include? p.link
          cache << p.link
        end
      rescue Capybara::ElementNotFound => e
        puts "Retrying..."
      end
    end

  end

  def self.long_scrape_user_posts_method(username, scrape_length_in_seconds, include_meta_data:)
    visit "https://www.instagram.com/#{username}/"
    long_scrape_posts(scrape_length_in_seconds, include_meta_data: include_meta_data) { |p| yield p }
  end

  def self.scrape_user_posts(username, include_meta_data:)
    visit "https://www.instagram.com/#{username}/"
    scrape_posts(include_meta_data: include_meta_data) { |p| yield p }
  end


  #split away span tags from user info numbers
  def self.get_span_value(element)
    begin_split = "\">"
    end_split = "</span>"
    return element[/#{begin_split}(.*?)#{end_split}/m, 1]
  end

end
