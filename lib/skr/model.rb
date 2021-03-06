require_relative 'concerns/all'

module Skr

    def self.table_name_prefix
        Skr::Core.config.table_prefix
    end


    class Model < ::ActiveRecord::Base
        self.abstract_class = true

        include Concerns::Queries
        include Concerns::PubSub
        include Concerns::JsonAttributeAccess
        include Concerns::TrackModifications
        include Concerns::LockedFields
        include Concerns::CodeIdentifier
        include Concerns::RandomHashCode
        include Concerns::VisibleIdIdentifier

        include Concerns::ImmutableModel
        include Concerns::ExportMethods
        include Concerns::ExportScope
        include Concerns::ExportAssociations
        include Concerns::ExportJoinTables
        include Concerns::SanitizeJson
        include Concerns::ActsAsUOM
        include Concerns::StateMachine
        include Concerns::HasSkuLocLines
        include Concerns::HasGlTransaction
        include Concerns::IsOrderLike
        include Concerns::IsSkuLocLine
        include Concerns::AssociationExtensions
    end

end
