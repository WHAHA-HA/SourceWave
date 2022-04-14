# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'ready page:load', ->
  if $('#crawls.new')[0]? or $('#crawls.new_keyword_crawl')[0]? or $('#crawls.edit')[0]?
    $('#crawl_moz_da, #crawl_majestic_tf').ionRangeSlider(
      min: 0,
      max: 100)
    $('#crawl_notify_me_after').ionRangeSlider(
      min: 0,
      max: 3000)
	  
  startTimer = ->
    start_time = $('.crawl_start_time').data('start-time')
    $('.crawl_start_time').timer({
      action: 'start',
      seconds: start_time	
    })
	  
  startTimer(); 
		