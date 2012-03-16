class Lawger

	#File.delete('lawg')

	def self.lawg(str)
		File.open('lawg', 'a'){|file| file.write "#{str}\n"}
	end

end