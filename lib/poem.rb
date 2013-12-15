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

require_relative 'corpus'

class Poem
  def initialize(corpus, *args)
    raise ArgumentError.new('corpus must not be nil') if corpus.nil?
    raise ArgumentError.new('corpus must be a Corpus object') if not corpus.kind_of?(Corpus)

    @corpus = corpus
  end

  def compose
    raise 'This method must be overridden and return a String generated from the Corpus'
  end
end
