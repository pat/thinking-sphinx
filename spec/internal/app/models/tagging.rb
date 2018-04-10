# frozen_string_literal: true

class Tagging < ActiveRecord::Base
  belongs_to :tag
  belongs_to :article
end
