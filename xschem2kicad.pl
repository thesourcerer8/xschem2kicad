#!/usr/bin/perl -w

print "EESchema-LIBRARY Version 2.4\n";
print "#encoding utf-8\n";


foreach my $fn (</usr/share/pdk/sky130A/libs.tech/xschem/sky130_stdcells/*.sym>)
{
  my $symname=""; $symname=$1 if($fn=~m/\/([^\/]*)\.sym$/);
  print "#\n";
  print "# $symname\n";
  print "#\n";
  print "DEF $symname U 0 20 Y N 1 F N\n";
  open IN,"<$fn";
  my %dir=();
  my %dirmap=("in"=>"I","out"=>"O","inout"=>"B");
  while(<IN>)
  {
    $dir{$1}=$dirmap{$2} if(m/name=(\w+) dir=(\w+)/);
  }
  close IN;
  print "F0 \"SC\" -350 1350 50 H V C CNN\n";
  print "F1 \"$symname\" 400 1350 50 H V R CNN\n";
  print "F2 \"\" 0 -1500 50 H I C CNN\n";
  print "F3 \"\" 0 0 50 H I C CNN\n";
  print "DRAW\n";
  open IN,"<$fn";
  my $nT=1;
  while(<IN>)
  {
    if(m/^T \{([^\}]*)\} (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) \{([\^}]*)\}/) # Text
    {
      my ($text,$x1,$y1,$rot,$mirr)=($1,int($2*10),int($3*-10),int($4*10),int($5*10));
      $text=~s/>//;$text=~s/ //;
      $text="~" if($text eq "");
      $text="\"$text\"" if($text!~m/^\w+/);
      #print "X $text $text $x1 $y1 200 U 50 50 1 0 I\n";
      print "T 0 $x1 $y1 50 0 0 0 $text Normal 0 C C\n";
            #T 0 0   150 50 0 0 0 2x    Normal 0 C C
      $nT++;
    }
    if(m/^B (\d+) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) \{(.*)\}/) # Rectangle
    {
      my($num,$x1,$y1,$x2,$y2,$data)=($1,int($2*10),int($3*-10),int($4*10),int($5*-10),$6);
      print "S $x1 $y1 $x2 $y2 0 1 1 F\n";
    }
    if(m/^L (\d+) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) \{(.*)\}/) # L Line
    {
      my($num,$x1,$y1,$x2,$y2,$data)=($1,int($2*10),int($3*-10),int($4*10),int($5*-10),$6);
      print "P 2 0 0 1 $x1 $y1 $x2 $y2 N\n";
    }
    if(m/^A (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) \{(.*)\}/) # A Arc
    {
      my($lay,$x1,$y1,$rad,$sa,$pa)=($1,int($2*10),int($3*-10),int($4*10),int($5*10),int($6*10));
      my $ea=$sa+$pa;
      if($ea>3600)
      {
        print "A $x1 $y1 $rad $sa 3600 0 0 1 N $x1 $y1 $x1 $y1\n";
        print "A $x1 $y1 $rad 0 ".($ea-3600)." 0 0 1 N $x1 $y1 $x1 $y1\n";
      }
      else
      {      
        print "A $x1 $y1 $rad $sa $ea 0 0 1 N $x1 $y1 $x1 $y1\n";
      }
    }



  }
  close IN;
  print "ENDDRAW\n";
  print "ENDDEF\n";
  print "#\n";
  print "#End Library\n";
}
