module Skr

    module BusinessEntity

        extend ActiveSupport::Concern

        included do
            has_random_hash_code
            has_code_identifier from: 'name'

            belongs_to :billing_address,  class_name: 'Skr::Address',     export: { writable: true }
            belongs_to :shipping_address, class_name: 'Skr::Address',     export: { writable: true }
            belongs_to :terms,            class_name: 'Skr::PaymentTerm', export: { writable: true }

            delegate_and_export :terms_code, :terms_description

            validates :name,  presence: true
            validates :terms, :billing_address, :shipping_address, set: true

            before_validation :set_defaults, :on=>:create
        end

    end

end
