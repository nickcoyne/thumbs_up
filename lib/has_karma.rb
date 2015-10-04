module ThumbsUp #:nodoc:
  module Karma #:nodoc:

    def self.included(base)
      base.extend ClassMethods
      class << base
        attr_accessor :karmic_objects
      end
    end

    module ClassMethods
      def has_karma(voteable_type, options = {})
        include ThumbsUp::Karma::InstanceMethods
        extend  ThumbsUp::Karma::SingletonMethods
        self.karmic_objects ||= {}
        self.karmic_objects[voteable_type.to_s.classify.constantize] = [ (options[:as] ? options[:as].to_s.foreign_key : self.name.foreign_key), [ (options[:weight] || 1) ].flatten.map(&:to_f) ]
      end
    end

    module SingletonMethods

      # Not yet implemented. Don't use it!
      # Find the most popular users
      # def find_most_karmic
      #   self.all
      # end

    end

    module InstanceMethods
      def karma(options = {})
        self.class.base_class.karmic_objects.collect do |object, params|

          upvotes, downvotes = build_karma_query(object, params)

          if params[1].length == 1 # Only count upvotes, not downvotes.
            (upvotes.count.to_f * params[1].first).round
          else
            (upvotes.count.to_f * params[1].first - downvotes.count.to_f * params[1].last).round
          end
        end.sum
      end

      private

      def build_karma_query(o, p)
        # v = o.joins(Vote.table_name).on(Vote.arel_table[:voteable_type].eq(o.to_s).and(Vote.arel_table[:voteable_id].eq(o.arel_table[o.primary_key])))
        # v = v.join(self.class.base_class.table_name).on(self.class.base_class.arel_table[self.class.base_class.primary_key].eq(o.arel_table[p[0]]))
        # v = v.where(self.class.base_class.arel_table[self.class.base_class.primary_key].eq(self.id))
        # puts v.to_sql
        v = o
            .joins(Vote.table_name, self.class.base_class.table_name)
            .where(Vote.arel_table[:voteable_type].eq(o.to_s).and(Vote.arel_table[:voteable_id].eq(o.arel_table[o.primary_key])))
            .where(self.class.base_class.arel_table[self.class.base_class.primary_key].eq(o.arel_table[p[0]]))
            .where(self.class.base_class.arel_table[self.class.base_class.primary_key].eq(self.id))
        [ v.where(Vote.arel_table[:vote].eq(true)), v.where(Vote.arel_table[:vote].eq(false)) ]
      end
    end

  end
end
