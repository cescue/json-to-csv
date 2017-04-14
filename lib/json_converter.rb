require 'csv'
require 'json'

class JsonConverter
  # Generate and return a csv representation of the data
  def generate_csv(json, headers=true, nil_substitute='')
    csv = convert_to_csv json, nil_substitute
    headers_written = false

    generated_csv = CSV.generate do |output|
      csv.each do |row|
        if headers_written === false && headers === true
          output << row.keys && headers_written = true
        end

        output << row.values
      end
    end

    generated_csv
  end

  # Generate a csv representation of the data, then write to file
  def write_to_csv(json, output_filename='out.csv', headers=true, nil_substitute='')
    csv = convert_to_csv json, nil_substitute
    headers_written = false 

    CSV.open(output_filename.to_s, 'w') do |output_file|
      csv.each do |row|
        if headers_written === false && headers === true
          output_file << row.keys && headers_written = true
        end

        output_file << row.values
      end
    end
  end

  private

  # Perform the actual conversion
  def convert_to_csv(json, nil_substitute)
    json = JSON.parse json if json.is_a? String

    in_array = array_from json
    out_array = []

    # Replace all nil values with the value of nil_substitute; The presence
    # of nil values in the data will usually result in uneven rows 
    in_array.map! { |x| nils_to_strings x, nil_substitute }

    in_array.each do |row|
      out_array[out_array.length] = flatten row
    end

    out_array
  end

  # Recursively convert all nil values of a hash to a specified string
  def nils_to_strings(hash, replacement)
    hash.each_with_object({}) do |(k,v), object|
      case v
      when Hash
        object[k] = nils_to_strings v, replacement
      when nil
        object[k] = replacement.to_s
      else
        object[k] = v
      end
    end
  end

  # Recursively flatten a hash (or array of hashes)
  def flatten(target, path='')
    scalars = [String, Integer, Fixnum, FalseClass, TrueClass]
    columns = {}

    if [Hash, Array].include? target.class
      target.each do |k, v|
        new_columns = flatten(v, "#{path}#{k}/") if target.class == Hash
        new_columns = flatten(k, "#{path}#{k}/") if target.class == Array
        columns = columns.merge new_columns
      end

      return columns
    elsif scalars.include? target.class
        # Remove trailing slash from path
        end_path = path[0, path.length - 1]
        columns[end_path] = target
        return columns
    else
      return {}
    end
  end

  # Attempt to identify what elements of a hash are best represented as rows
  def array_from(json_hash)
    queue, next_item = [], json_hash
    while !next_item.nil?

      return next_item if next_item.is_a? Array

      if next_item.is_a? Hash
        next_item.each do |k, v|
          queue.push next_item[k]
        end
      end

      next_item = queue.shift
    end

    return [json_hash]
  end
end
