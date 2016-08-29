# Copied from ActiveSupport so we don't have to add ActiveSupport as a dependency just for this method.
class String
  # Makes an underscored, lowercase form from the expression in the string.
  #
  # Changes '::' to '/' to convert namespaces to paths.
  #
  #   'ActiveModel'.underscore         # => "active_model"
  #   'ActiveModel::Errors'.underscore # => "active_model/errors"
  #
  # As a rule of thumb you can think of +underscore+ as the inverse of
  # +camelize+, though there are cases where that does not hold:
  #
  #   'SSLError'.underscore.camelize # => "SslError"
  def underscore
    return self unless self =~ /[A-Z-]|::/
    word = self.to_s.gsub(/::/, '/')
    # word.gsub!(/(?:(?<=([A-Za-z\d]))|\b)(#{inflections.acronym_regex})(?=\b|[^a-z])/) { "#{$1 && '_'}#{$2.downcase}" }
    word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
    word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
    word.tr!("-", "_")
    word.downcase!
    word
  end
end
