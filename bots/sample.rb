module Boneyard
module Bots

class Sample < Bot

	def initialize(name)
		super(name)
	end
	
	def bid
		@counts = {}
	
		bones.each { |bone|
			@counts[bone.top]    = (@counts[bone.top]    || 0) + 1
			@counts[bone.bottom] = (@counts[bone.bottom] || 0) + 1
			@counts[7]           = (@counts[7]           || 0) + 1 if bone.double?
		}
		
		@high_suite, @high_count = @counts.to_a.sort{ |x, y| y[1] <=> x[1] }[0]

		# Dumb
		return @high_count <= 3 ? rand(22) : rand(43)
	end
	
	def select_trump
		puts "#{name}: select suite #{@high_suite} for count #{@high_count}"

		@high_suite
	end
	
	def play_round
		best_bot, best_bone = best_play

		if best_bot.nil?
			cast_initial_bone
		else
			cast_response_bone(best_bot, best_bone)
		end
	end

	def cast_initial_bone
		legal_bones[0]
	end

	def cast_response_bone(best_bot, best_bone)
		legal_bones[0]
	end

end

end
end
