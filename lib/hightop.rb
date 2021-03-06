require "hightop/version"
require "active_record"

module Hightop
  def top(column, limit = nil, options = {})
    if limit.is_a?(Hash)
      options = limit
      limit = nil
    end

    distinct = options[:distinct] || options[:uniq]
    order_str = column.is_a?(Array) ? column.map(&:to_s).join(", ") : column
    relation = group(column).order("count_#{distinct || 'all'} DESC, #{order_str}")
    if limit
      relation = relation.limit(limit)
    end

    unless options[:nil]
      (column.is_a?(Array) ? column : [column]).each do |c|
        relation = relation.where("#{c} IS NOT NULL")
      end
    end

    if options[:min]
      relation = relation.having("COUNT(#{distinct ? "DISTINCT #{distinct}" : '*'}) >= #{options[:min].to_i}")
    end

    if distinct
      # since relation.respond_to?(:distinct) can't be used
      if ActiveRecord::VERSION::MAJOR > 3
        relation.distinct.count(distinct)
      else
        relation.uniq.count(distinct)
      end
    else
      relation.count
    end
  end
end

ActiveRecord::Base.send :extend, Hightop
