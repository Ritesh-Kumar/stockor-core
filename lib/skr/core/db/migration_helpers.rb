require 'skr/core/configuration'

module Skr
    module Core
        module DB

            module TableFields

                def skr_code_identifier
                    column( :code, :string,  :null=>false )
                    skr_extra_indexes['code'] = {}
                end

                def skr_visible_id
                    column( :visible_id, :integer,  :null=>false )
                    skr_extra_indexes['visible_id'] = {
                        function: 'CAST(visible_id AS VARCHAR)'
                    }
                end

                # track modifications
                def skr_track_modifications( *args )
                    opts = args.extract_options!
                    column( :created_at, :datetime,   :null=>false )
                    column( :created_by_id, :integer, :null=>false )
                    unless opts[:create_only]
                        column( :updated_at, :datetime,   :null=>false )
                        column( :updated_by_id, :integer, :null=>false )
                    end
                end

                def skr_currency( name, options )
                    options[ :precision ] ||= 15
                    options[ :scale ]     ||= 2
                    column( name, :decimal, options )
                end

                # An skr_reference combines a belongs_to / has_one column
                # with a postgresql foreign key reference.
                def skr_reference( to_table, *args )
                    options = args.extract_options!

                    options[:column] ||= to_table.to_s + '_id'

                    column( options[:column], :integer, :null=>options[:null] || false )

                    # to_table =  Skr::Core.config.table_prefix + ( options[:to_table] || to_table ).to_s

                    skr_foreign_keys[ options[:to_table] || to_table ] = options
                end

                def skr_foreign_keys
                    @skr_foreign_keys ||= {}
                end

                def skr_extra_indexes
                    @skr_extra_indexs ||= {}
                end
            end

            module MigrationMethods

                def create_skr_table(table_name, *args, &block)
                    definition = nil
                    create_table( Skr::Core.config.table_prefix + table_name, *args ) do | td |
                        # Thanks for the trick from the Foreigner gem!
                        # in connection_adapters/abstract/schema_statements
                        definition = td
                        block.call(td) unless block.nil?
                    end
                    definition.skr_foreign_keys.each do |to_table, options |
                        skr_add_foreign_key( table_name, to_table, options )
                    end
                    definition.skr_extra_indexes.each do | index_column, options |
                        skr_add_index( table_name, index_column, options )
                    end
                end

                def skr_add_index( table_name, columns, options={} )
                    table_name = Skr::Core.config.table_prefix + table_name.to_s
                    if options[:function]
                        unique = options[:unique] ? 'unique' : ''
                        name   = table_name + 'indx_' + columns
                        execute( "create #{unique} index #{name} on #{table_name}(#{options[:function]})" )
                    else
                        add_index( table_name, columns, options  )
                    end
                end

                def skr_add_foreign_key( table_name, to_table, options = {} )
                    from_table = Skr::Core.config.table_prefix + table_name.to_s
                    to_table   = Skr::Core.config.table_prefix + to_table.to_s
                    # table_name #from_table = Skr::Core.config.table_prefix + table_name
                    column  = options[:column] || "#{to_table.to_s.singularize}_id"
                    foreign_key_name = options.key?(:name) ? options[:name].to_s : "#{from_table}_#{column}_fk"

                    primary_key = options[:primary_key] || "id"
                    dependency = case options[:dependent]
                                 when :nullify then "ON DELETE SET NULL"
                                 when :delete  then "ON DELETE CASCADE"
                                 when :restrict then "ON DELETE RESTRICT"
                                 else ""
                                 end
                    sql = "ALTER TABLE #{quote_table_name(from_table)} " +
                          "ADD CONSTRAINT #{quote_column_name(foreign_key_name)} " +
                          "FOREIGN KEY (#{quote_column_name(column)}) " +
                          "REFERENCES #{quote_table_name( to_table )}(#{primary_key})"
                    sql << " #{dependency}" if dependency.present?
                    sql << " #{options[:options]}" if options[:options]

                    execute(sql)
                end

                def drop_skr_table( table_name, *args )
                    drop_table( Skr::Core.config.table_prefix + table_name )
                end
            end

            module CommandRecorder
                def create_skr_table(*args)
                    record(:create_skr_table, args)
                end

                def drop_skr_table(*args)
                    record(:drop_skr_table, args)
                end

                def invert_create_skr_table(args)
                    from_table, to_table, add_options = *args
                    add_options ||= {}
                    if add_options[:name]
                        options = {name: add_options[:name]}
                    elsif add_options[:column]
                        options = {column: add_options[:column]}
                    else
                        options = to_table
                    end
                    [:drop_skr_table, [from_table, options]]
                end
            end

        end

    end
end

ActiveRecord::Migration::CommandRecorder.class_eval do
    include Skr::Core::DB::CommandRecorder
end

ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.class_eval do
    include Skr::Core::DB::MigrationMethods
end

ActiveRecord::ConnectionAdapters::TableDefinition.class_eval do
    include Skr::Core::DB::TableFields
end
