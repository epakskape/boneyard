require 'rexml/rexml'
require 'rexml/document'

class Array
	def shuffle
		self.dup.shuffle!
	end
	def shuffle!
		length.downto(1) { |n|
			push delete_at(rand(n))
		}

		self
	end
	def ^(ary)
		intersect = self & ary	
		self.dup.delete_if { |x|
			intersect.include?(x)
		}
	end
end

module Boneyard

module Trump
	Zero    = 0
	One     = 1
	Two     = 2
	Three   = 3
	Four    = 4
	Five    = 5
	Six     = 6
	Doubles = 7

	AllTrumps = [ Zero, One, Two, Three, Four, Five, Six, Doubles ]
	Names = {
		 Zero    => "Zero",
		 One     => "One",
		 Two     => "Two",
		 Three   => "Three",
		 Four    => "Four",
		 Five    => "Five",
		 Six     => "Six",
		 Doubles => "Doubles"
	}
end

module SuitePosition
	Top     = 1
	Bottom  = 2
end

class InvalidBonePlayedException < Exception
end

class TooManyPlayersException < Exception
end

class Round
	def initialize
		@plays = []
		@points_won = 0
	end

	def determine_winner(game)
		find_winning_play(game)
		@winner
	end

	def find_winning_play(game)
		highest_degree = -1
		trump_degree   = nil
		trump_played   = false
		trump_maxed    = false
		normal_maxed   = false

		return nil if @plays.empty?

		@points_won = 0
		@winner     = nil

		@plays.each { |play|
			bot, bone = play

			if bone.is_trump(game)
				trump_played = true

				if trump_degree.nil? or 
					((bone.degree > trump_degree and trump_maxed == false) or 
					 bone.double?)
					trump_maxed   = (bone.double? and game.trump != Trump::Doubles)
					trump_degree  = bone.degree
					@winner       = bot
					@winning_bone = bone
				end
			else
				if trump_played == false and bone.suite == @suite and 
					((bone.degree > highest_degree and normal_maxed == false) or 
					 bone.double?)
					normal_maxed   = bone.double?
					highest_degree = bone.degree
					@winner        = bot
					@winning_bone  = bone
				end
			end

			@points_won += bone.points
		}

		@points_won += 1

		[@winner,@winning_bone]
	end

	attr_accessor :suite
	attr_reader   :plays
	attr_reader   :winner
	attr_reader   :points_won

end

class Bone

	def initialize(top, bottom)
		@suite_position = SuitePosition::Top
		@top = top
		@bottom = bottom
	end

	def object_id
		(suite_position << 8) + (top << 4) + bottom
	end

	def suite
		return suite_position == SuitePosition::Top ? top : bottom
	end

	def degree
		return suite_position == SuitePosition::Top ? bottom : top
	end

	def is_trump(game)
		if game.trump == Trump::Doubles and top == bottom or
			suite == game.trump
			true
		else
			false
		end
	end

	def double?
		top == bottom
	end

	def autodetermine_suite(game)
		# If this is a trump piece
		if top == game.trump
			@suite_position = SuitePosition::Top
		elsif bottom == game.trump
			@suite_position = SuitePosition::Bottom
		# If a required suite has been selected, try to coerce the peice
		# to the proper suite
		elsif game.required_suite
			if @top == game.required_suite
				@suite_position = SuitePosition::Top
			else
				@suite_position = SuitePosition::Bottom
			end
		end
	end

	def points
		if (@top > 0 or @bottom > 0) and (@top + @bottom) % 5 == 0
			@top + @bottom
		else
			0
		end
	end

	def to_s
		"#{suite}/#{degree}"
	end

	attr_accessor :suite_position
	attr_reader   :top
	attr_reader   :bottom

	# 7!
	AllBones = [
		Bone.new(0, 0), Bone.new(0, 1), Bone.new(0, 2), Bone.new(0, 3), Bone.new(0, 4), Bone.new(0, 5), Bone.new(0, 6),
		Bone.new(1, 1), Bone.new(1, 2), Bone.new(1, 3), Bone.new(1, 4), Bone.new(1, 5), Bone.new(1, 6),
		Bone.new(2, 2), Bone.new(2, 3), Bone.new(2, 4), Bone.new(2, 5), Bone.new(2, 6),
		Bone.new(3, 3), Bone.new(3, 4), Bone.new(3, 5), Bone.new(3, 6),
		Bone.new(4, 4), Bone.new(4, 5), Bone.new(4, 6),
		Bone.new(5, 5), Bone.new(5, 6),
		Bone.new(6, 6),
	]

end

class Bot
	
	def initialize(name)
		@name  = name
		@bones = []
	end

	def name
		@name
	end

	def bid
	end

	def select_trump
	end

	def play_round
	end

	def game_over
	end

	def to_s
		name
	end

	def legal_bones
		legal = @bones.dup.delete_if { |bone|
			@game.required_suite and bone.top != @game.required_suite and bone.bottom != @game.required_suite
		}

		if legal.empty?
			legal = @bones
		end
		
		legal
	end

	def best_play
		@game.current_round_best_play
	end

	def teammate?(bot)
		left.left == bot
	end

	def each_bot(&block)
		current_bot = self
		begin 
			block.call(current_bot)
			current_bot = current_bot.left
		end until current_bot == self
	end

	def each_bot_with_index(&block)
		current_bot = self
		index       = 0
		begin 
			block.call(current_bot, index)
			index += 1
			current_bot = current_bot.left
		end until current_bot == self
	end


	attr_accessor :left
	attr_accessor :game
	attr_reader   :bones
	attr_accessor :starting_bones

end

class Game

	def initialize
		@bots  = []
		@seats = nil
	end

	def add_bot(bot)
		if @bots.length == 4
			raise TooManyPlayersException, "There are already four players."
		end

		bot.game = self

		@bots << bot
	end

	def play
		@rounds = []

		shook
		assign_seats if @seats.nil?	
		assign_bones
		play_rounds(collect_bids)
		@winner = determine_winner

		puts "overall winner: #{@winner[0]} with #{@winner[1]} points (bid #{@bids[@winner[0]]})"
	end

	def save(path)
		doc  = REXML::Document.new
		doc.add_element(REXML::Element.new("Boneyard"))
		
		xgame  = doc.root.add_element(REXML::Element.new("Game"))
		xtrump = xgame.add_element(REXML::Element.new("Trump"))
		xtrump.add_text(REXML::Text.new(Trump::Names[trump].to_s))
		xwinner = xgame.add_element(REXML::Element.new("Winner"))
		xwinner.add_text(REXML::Text.new(@winner[0].to_s))
		xptswon = xgame.add_element(REXML::Element.new("PointsWon"))
		xptswon.add_text(REXML::Text.new(@winner[1].to_s))
		xplayers = xgame.add_element(REXML::Element.new("Players"))

		@bots.each { |bot|
			xplayer = xplayers.add_element(REXML::Element.new("Player"))
			xplayer.add_attribute(REXML::Attribute.new("name", bot.name))
			xplayer.add_attribute(REXML::Attribute.new("class", bot.class))

			xbones  = xplayer.add_element(REXML::Element.new("StartingBones"))	

			bot.starting_bones.each { |bone|
				xbone = xbones.add_element(REXML::Element.new("Bone"))
				xbone.add_attribute(REXML::Attribute.new("suite", bone.suite))
				xbone.add_attribute(REXML::Attribute.new("degree", bone.degree))
				xbone.add_attribute(REXML::Attribute.new("istrump", bone.is_trump(self)))
			}
		}

		xrounds = xgame.add_element(REXML::Element.new("Rounds"))

		@rounds.each { |round|
			xround = xrounds.add_element(REXML::Element.new("Round"))

			xsuite = xround.add_element(REXML::Element.new("Suite"))
			xsuite.add_text(REXML::Text.new(round.suite.to_s))
			xwinner = xround.add_element(REXML::Element.new("Winner"))
			xwinner.add_text(REXML::Text.new(round.winner.to_s))
			xptswon = xround.add_element(REXML::Element.new("PointsWon"))
			xptswon.add_text(REXML::Text.new(round.points_won.to_s))

			round.plays.each { |play|
				bot, bone = play

				xbone = xround.add_element(REXML::Element.new("Bone"))
				
				xbone.add_attribute(REXML::Attribute.new("suite", bone.suite))
				xbone.add_attribute(REXML::Attribute.new("degree", bone.degree))
				xbone.add_attribute(REXML::Attribute.new("istrump", bone.is_trump(self)))
				xbone.add_text(REXML::Text.new(bot.to_s))
			}
		}

		File.open(path, "w") { |file|
			file.write(doc.to_s)
		}
	end

	def first_bot
		@seats[0]
	end

	def bones_used
		@bones_available ^ Bone.AllBones
	end

	def current_round
		@round
	end
	
	def current_round_plays
		@round.plays
	end

	def current_round_best_play
		@round.find_winning_play(self)
	end
	
	attr_reader :bones_available	
	attr_reader :required_suite
	attr_reader :trump

protected

	def shook
		@bones_available = Bone::AllBones.shuffle
		@bids            = {}
	end

	def assign_seats
		@seats = @bots.shuffle

		@seats.each_with_index { |bot, index|
			bot.left = @seats[(index + 3) % 4]
		}
	end

	def assign_bones
		@seats.each { |bot|
			bot.bones.clear
			7.times {
				bot.bones << @bones_available.shift
			}
			bot.starting_bones = bot.bones.dup
		}
	end

	def collect_bids
		highest_bidder = nil
		highest_bid    = -1

		first_bot.each_bot_with_index { |bot, index|
			bid = bot.bid
			
			if bid > highest_bid or bid == 0
				highest_bidder = bot
				highest_bid    = bid

				break if bid == 0
			end	

			@bids[bot] = bid
		}

		# Allow the highest bidder to select the trump
		@trump = highest_bidder.select_trump

		puts "trump is #{@trump}"

		highest_bidder
	end

	def play_rounds(first_player)
		@rounds = []

		# Play each round
		1.upto(7) { |round_num|
			@round = Round.new

			@required_suite = nil

			# Allow each player to cast their bone
			first_player.each_bot { |bot|
				bone = bot.play_round

				bone.autodetermine_suite(self)

				if @required_suite.nil?
					@required_suite = @round.suite = bone.suite 
				end

				validate_play(bot, bone)

				@round.plays << [bot, bone]	
			}

			# Determine the winner of the round
			first_player = @round.determine_winner(self)

			# Add it to the list of rounds
			@rounds << @round
		}
	end

	def validate_play(bot, bone)
		puts "#{bot} played #{bone}"

		# Make sure the bot played one of their pieces
		if bot.bones.include?(bone) == false
			raise InvalidBonePlayedException, "Bot #{bot} cast a bone they do not have: #{bone}"
		end

		# Make sure the bot played a required piece
		if bone.suite != @required_suite and bone.is_trump(self) == false
			bot.bones.each { |avail|
				if avail.top == @required_suite or avail.bottom == @required_suite
					raise InvalidBonePlayedException, "Bot #{bot} played #{bone}, but is required to play #{avail}"
				end
			}
		end

		bot.bones.delete(bone)
	end

	def determine_winner
		points = {}

		@rounds.each { |round|
			points[round.winner] = (points[round.winner] || 0) + round.points_won
		}

		# If a bot bid nil and they got it, they win.
		@bids.each_pair { |bot, bid|
			if bid == 0 and points[bot] == 0
				return [bot,0]
			end
		}

		# Otherwise, find the bot with the most points.
		highest_bot    = nil
		highest_points = 0

		points.each_pair { |bot, points|
			if points > highest_points
				highest_bot    = bot
				highest_points = points
			end
		}

		[highest_bot,highest_points]
	end

end

end

require 'bots/sample'

game = Boneyard::Game.new
game.add_bot(Boneyard::Bots::Sample.new("bravo"))
game.add_bot(Boneyard::Bots::Sample.new("alpha"))
game.add_bot(Boneyard::Bots::Sample.new("charlie"))
game.add_bot(Boneyard::Bots::Sample.new("echo"))
game.play
game.save('game.xml')
