class WebhooksController < ApplicationController
  skip_forgery_protection

  def paypal
    # Establece la autenticación con PayPal usando las credenciales adecuadas
    paypal_client_id = Rails.application.credentials.dig(:paypal, :client_id)
    paypal_secret = Rails.application.credentials.dig(:paypal, :secret)

    paypal_client = PayPal::Client.new(
      client_id: paypal_client_id,
      secret: paypal_secret
    )

    # Lee el payload del webhook
    payload = request.body.read

    # Verifica la autenticidad del webhook de PayPal
    unless paypal_client.verify_webhook_signature(request.headers, payload)
      head :bad_request
      return
    end

    # Parsea el evento recibido
    event = paypal_client.parse_webhook_event(payload)

    # Maneja el evento según su tipo
    case event.event_type
    when 'CHECKOUT.ORDER.APPROVED'
      order_id = event.resource.id
      # Aquí puedes actualizar tu base de datos o realizar otras acciones necesarias
      # basadas en el evento de aprobación de orden

      # Por ejemplo, podrías actualizar el estado de la orden en tu base de datos
      order = Order.find_by(paypal_order_id: order_id)
      order.update(status: 'approved') if order
    when 'PAYMENT.CAPTURE.COMPLETED'
      payment_id = event.resource.id
      # Maneja el evento de captura de pago completada
    else
      # Maneja otros tipos de eventos si es necesario
    end

    # Devuelve una respuesta exitosa
    head :ok
  rescue StandardError => e
    # Maneja errores y devuelve una respuesta de error
    Rails.logger.error "Error processing PayPal webhook: #{e.message}"
    head :internal_server_error
  end
end
