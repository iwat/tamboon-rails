class OmiseFund < Fund
  def initialize(charge)
    @charge = charge
  end

  def amount
    @charge.amount
  end

  def capture
    @charge.capture

    unless @charge.paid
      raise "[pay_error] #{t('.failure')}"
    end
  end
end

