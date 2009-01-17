class Developer < ActiveRecord::Base
  define_index do
    indexes country,  :facet => true
    indexes state,    :facet => true
    has age,          :facet => true
    facet city
  end
end