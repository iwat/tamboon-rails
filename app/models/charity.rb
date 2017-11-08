class Charity < ActiveRecord::Base
  validates :name, presence: true

  def self.random
    find(ids.sample) # not the best optimal but the best brevity
  end

  def donate(fund)
    new_total = total + fund.amount
    update_attribute :total, new_total
    fund.capture
  end
end
