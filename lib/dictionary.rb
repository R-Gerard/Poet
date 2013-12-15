# Copyright (C) 2013 Rusty Gerard
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

require 'set'

class Dictionary

  def initialize
    @dictionary = Set.new
  end

  # init_from_collection
  #
  # Populates the Hash table of irregular words from another Hash.
  #
  def init_from_collection(collection)
    raise ArgumentError.new('collection must not be nil') if collection.nil?
    raise ArgumentError.new('collection must be a container that implements include? (e.g. Set)') if not collection.respond_to?(:include?)

    @dictionary.merge!(collection)
  end

  # init_from_csv_file
  #
  # Populates the Hash table of irregular words from a comma-separated values file.
  #
  def init_from_csv_file(filename)
    File.open(filename, 'r') do |file|
      file.each_line do |line|
        if line.start_with?('#') then next end

        line.split(',').each do |term|
          @dictionary << term.strip.downcase
        end
      end
    end
  end

  def include?(term)
    @dictionary.include?(term)
  end
end
