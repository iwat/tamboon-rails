class Charity < ActiveRecord::Base
  validates :name, presence: true

  def self.random
    find(ids.sample) # not the best optimal but the best brevity
  end

  def credit_amount(amount)
    with_lock do
      new_total = total + amount
      update_attribute :total, new_total
    end
  end
end
