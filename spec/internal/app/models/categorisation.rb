class Categorisation < ActiveRecord::Base
  belongs_to :category
  belongs_to :product

  after_commit :update_product

  private

  def update_product
    product.reload
    ThinkingSphinx::RealTime.callback_for(:product, [:product]).after_save self
  end
end
