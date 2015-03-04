require "public_suffix"
require "active_model/validator"

class PublicSuffixValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    return unless [ :hostname, :domain, :subdomain ].include?(attribute.to_sym)
    unless PublicSuffix.valid?(value)
      record.errors[attribute] << (options[:message] || "is not a valid domain on the Public Suffix List")
    end
  end

end
