# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

#jQuery ->
#	$(".selectpicker").select2(
#		width: '100%',
#		theme: 'bootstrap',
#		minimumResultsForSearch: -1
#	);
#
#	Stripe.setPublishableKey($('meta[name="stripe-key"]').attr('content'))
#	subscription.setupForm()
#
#subscription =
#	setupForm: ->
#		$('#new_subscription').submit ->
#			$('input[type=submit]').attr('disabled', true)
#			subscription.processCard()
#			false
#
#	processCard: ->
#		card =
#			number: $('#card_number').val()
#			cvc: $('#card_code').val()
#			expMonth: $('#card_month').val()
#			expYear: $('#card_year').val()
#		Stripe.createToken(card, subscription.handleStripeResponse)
#
#	handleStripeResponse: (status, response) ->
#		if status == 200
#			$('#stripe_card_token').val(response.id)
#			$('#new_subscription')[0].submit()
#		else
#			$('#stripe_error').text(response.error.message)
#			$('input[type=submit]').attr('disabled', false)
#
