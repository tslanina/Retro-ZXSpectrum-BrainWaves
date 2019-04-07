rm *.tap
pasmo --bin bw.s bw.b
pasmo --tapbas bw.s bw.tap
ls -lag *.b
