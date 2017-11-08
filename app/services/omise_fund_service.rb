module OmiseFundService
  class << self
    def create_fund(amount:, currency:, card:, description:)
      charge = Omise::Charge.create({
        amount:      amount,
        currency:    currency,
        card:        card,
        description: description,
        capture:     false,
      })

      OmiseFund.new(charge)
    end
  end
end
