module Skr
    module Concerns

        module SanitizeJson
            extend ActiveSupport::Concern

            # SanitizeJson is where all the exports_XXX concerns come together.  It's responsible for only allowing
            # associations and other data to be saved that have been marked as safe.
            module ClassMethods

                # Takes in a hash containing attribute name/value pairs, as well as sub hashes/arrays.
                # It returns only the attributes that have been marked as exportable
                # @param json [Hash]
                # @param user [UserProxy,User] who is performing request
                def sanitize_json(json, user = Skr::UserProxy.current)
                    return {} unless user.can_write?(self)
                    json.each_with_object(Hash.new) do | kv, result |
                        ( key, value ) = kv

                        if json_attribute_is_allowed?( key.to_sym, user )
                            result[ key ] = value
                        else
                            # allow nested params to be specified using Rails _attributes
                            name = key.to_s.gsub(/_attributes$/,'')

                            next unless has_exported_nested_attribute?( name, user )

                            klass_name = self.reflections[ name.to_sym ].class_name
                            klass = klass_name.safe_constantize || "Skr::#{klass_name}".constantize

                            # only Hash, Array & nil is valid for nesting attributes
                            cleaned = case value
                                      when Hash  then klass.sanitize_json( value, user )
                                      when Array then value.map{ | nested | klass.sanitize_json( nested, user ) }
                                      else
                                          nil
                                      end
                            result[ (name + '_attributes').to_sym ] = cleaned unless cleaned.blank?
                        end
                    end
                end

            end

        end

    end

end
