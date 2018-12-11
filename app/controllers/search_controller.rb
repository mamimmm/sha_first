require 'twitter'
require 'natto'

class SearchController < ApplicationController
  def index
  end

  def about
  end

  def result
    # console

    @username = params[:username]
    logger.info "username:"
    logger.info @username

    @client = Twitter::REST::Client.new do |config|
        config.consumer_key   =  ENV['CONSUMER_KEY']
        config.consumer_secret  =  ENV['CONSUMER_SECRET']
        config.access_token   =  ENV['ACCESS_TOKEN']
        config.access_token_secret = ENV['ACCESS_TOKEN_SECRET']
    end

    @Texts = ""
    # 特定ユーザのtimeline取得
    @client.user_timeline(@username, { count: 50, include_rts: false, exclude_replies: false }).each do |timeline|
      @Texts << @client.status(timeline.id).text
    end

    @ProperNouns = Hash.new(0)

    @TextArray = []
    natto = Natto::MeCab.new(dicdir: "/usr/local/lib/mecab/dic/mecab-ipadic-neologd")
    natto.parse(@Texts) do |n|
      logger.info "Processing mecab parse..."
      logger.info "#{n.surface}" + ": " + "#{n.feature}"
      next if "#{n.feature}" !~ /固有名|名詞,一般/ # どの品詞を取りたいのかを指定。
      string = "#{n.surface}"
      @ProperNouns[string] += 1
    end


    @ProperNouns = @ProperNouns.sort_by{ | k, v | v }.reverse.to_h

    @ProperNouns.delete_if { |_, v| v < 3 }
    @ProperNouns.delete_if { |k, v| k == "https" }
    @ProperNouns.delete_if { |k, v| k == "t" }
    @ProperNouns.delete_if { |k, v| k == "co" }
    @ProperNouns.delete_if { |k, v| k == "you" }
    @ProperNouns.delete_if { |k, v| k == "ー" }
    @ProperNouns.delete_if { |k, v| k == "ーー" }
    @ProperNouns.delete_if { |k, v| k == "これ"}

    @label_string = "\""
    @count_string = ""

    @ProperNouns.each{|k, v|
      @label_string += k + "\",\""
      logger.info "Preparing label_string..."
      logger.info @label_string.html_safe
      @count_string += v.to_s + ","
      logger.info "Preparing count_string..."
      logger.info @count_string
    }
    @label_string = @label_string[0...-2]
    @label_string = @label_string.html_safe

  end
end
