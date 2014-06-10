# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
#

users = User.create([
  {
    email: 'foo@bar.com',
    name: 'bar'
  },
  {
    email: 'bar@bar.com',
    name: 'bar'
  },
])

categories = Category.create([
  {
    name: 'foo'
  },
  {
    name: 'bar'
  },
  {
    name: 'baz'
  }
])

posts = Post.create([
  {
    category: categories.sample,
    user: users.sample
  },
  {
    category: categories.sample,
    user: users.sample
  },
  {
    category: categories.sample,
    user: users.sample
  },
])

news_posts = Posts::News.create([
  {
    category: categories.sample,
    user: users.sample
  },
  {
    category: categories.sample,
    user: users.sample
  },
  {
    category: categories.sample,
    user: users.sample
  }
])

tags = Tag.create([
  {
    name: 'foo'
  },
  {
    name: 'bar'
  },
  {
    name: 'baz'
  }
])

Post.all.each do |post|
  post.tags = tags.sample(rand(4))
end
