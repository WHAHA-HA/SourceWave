# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'ready page:load', ->

  # $(document).on 'click', '#menu-button', filterDomainNav
  #   API.open();

  $('#my-menu').mmenu
    offCanvas:
      position : 'right',
      zposition : 'front'

  API = $('#my-menu').data('mmenu');
  
  $('#menu-button').click ->
    if !$('.new_domain_for_sale').is(':visible')
      $('.new_domain_for_sale').css('visibility', 'visible');
    API.open();
    # $('.filter_domains_side_nav_container').toggle();
	
  if $('#my-menu').length > 0
    $('#domain_for_sale_price, #domain_for_sale_trustflow, #domain_for_sale_citationflow, #domain_for_sale_da, #domain_for_sale_pa').ionRangeSlider(
      min: 0,
      max: 100)
    $('#domain_for_sale_user_rating').ionRangeSlider(
      min: 0,
      max: 5)
    $('#domain_for_sale_refdomains, #domain_for_sale_backlinks').ionRangeSlider(
      min: 0,
      max: 10000)
	  
  $('.refund_guarantee_tooltip').tooltip();