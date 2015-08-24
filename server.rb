require "sinatra"
require "pry"
require "pg"

def db_connection
  begin
    connection = PG.connect(dbname: 'news_aggregator_development')
    yield(connection)
  ensure
    connection.close
  end
end

# redirect to articles page
get "/" do
  redirect "/articles"
end

# main page to list all the articles
get "/articles" do
  article_array = []
  selector = []

  # read the articles out of CSV file
  db_connection do |conn|
    selector = conn.exec("SELECT title, url, description FROM articles")
  end

  selector.each do |art|
    article = Article.new(art['title'], art['url'], art['description'])
    article_array << article
  end

  erb :index, locals: {articles: article_array}
end


# post values to articles.csv
post "/articles" do
  title = params["title"]
  address = params["address"]
  description = params["description"]

  # write article to CSV file

  db_connection do |conn|
    conn.exec_params("INSERT INTO articles (title, url, description) VALUES ($1, $2, $3)", [title, address, description])
  end

  redirect "/articles"
end

# show form for submitting articles
get "/articles/new" do
  # flag variable to show whether or not link is already submitted
  erb :article_submit, locals: {title: "", description: "", flag: false}
end

# show the form after a link is repeated
get "/articles/new/:title/:description" do
  erb :article_submit, locals: {title: params[:title], description: params[:description], flag: true}
end

# article class
class Article
  attr_reader :title, :address, :description

  def initialize(title, address, description)
    @title = title
    @address = address
    @description = description
  end
end
