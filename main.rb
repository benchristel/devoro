require 'redis'
require 'nokogiri'
require 'curb'
require_relative './crawler.rb'

redis = Redis.new
crawler = Crawler.new(redis)
crawler.run
