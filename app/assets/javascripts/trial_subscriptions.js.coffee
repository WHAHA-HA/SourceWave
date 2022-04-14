# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'ready page:load', ->
  if $('#trial_subscriptions.new')[0]?
    # When the user hit's submit
    # - stop it
    # - disable the button
    # - get stripe token
    # - remove chance of Card Info being sent
    $('#subscription-submit').on 'click', (e)->
      # Stop Submit
      e.preventDefault()
	  
      if $("input[name=accept_terms]:checked").length > 0
        stripeRequestToken()
      else
        alert 'Please accept the terms before continuing'

    disableButton = ($button) ->
      # Disable Button
      $button.prop('disabled': true)
      $button[0].value = $button.data().disableWith

    removeCardInfo = () ->
      $('.card input').prop('name', '')

    # Fetches Stripe Token
    stripeRequestToken = ->
      Stripe.card.createToken($('form'), stripeResponseHandler)

    # Handles Error and Success
    stripeResponseHandler = (status, response) ->
      $form = $('.card')
      if (response.error)
        # Show the errors on the form
        $form.find('.payment-errors').addClass('alert alert-danger').text(response.error.message)
      else
        # Disable
        disableButton($(this))
        # response contains id and card, which contains additional card details
        token = response.id
        removeCardInfo()
        # Insert the token into the form so it gets submitted to the server
        $form.append($('<input type="hidden" name="stripeToken" />').val(token))
        # Remove Errors
        $form.find('.payment-errors').remove()
        $('#new_trial_subscription').submit()