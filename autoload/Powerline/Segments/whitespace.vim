let g:Powerline#Segments#whitespace#segments = Pl#Segment#Init(['whitespace',
	\ (exists(':Tagbar') > 0),
  \
	\ Pl#Segment#Create('trailing', '%{Powerline#Functions#whitespace#Check()}', Pl#Segment#Modes('!N')),
\ ])
