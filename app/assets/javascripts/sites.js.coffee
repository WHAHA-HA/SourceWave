# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'ready page:change', ->
	$('#available-submit-tag').on 'click', (e)->
		$('#available-sites-form').submit()
		
	$('#bookmarked-submit-tag').on 'click', (e)->
		$('#bookmark-sites-form').submit()
		
	console.log 'page changed'