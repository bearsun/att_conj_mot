# att_conj_mot

messy code for att_conj_mot study, but works OK for me.

#### generatesequence.m will generate a .mat file with all x,y for each ball.
You can adjust how many trials or balls you need. But it is not guranteed to work after mod.

#### Balls.m handles the dynamic of ball movements. It serves my experiment well.

#### trans360to20.m generate different speeds of ball movements based on the templates generated by generatesequence.m
since I was running a staircase design in my experiment.

#### track.m is the actually code I am running for the experiment. However, it depends on a 0.7G test_i20_500.mat file, which you can generate following the pipline above.

Hope it helps.

Liwei
