#!/usr/bin/perl -w

my $filename = 'sky130.lib';
open(FH, '>', $filename) or die $!;
print FH "EESchema-LIBRARY Version 2.4\n";
print FH "#encoding utf-8\n";

foreach my $fn (</usr/share/pdk/sky130A/libs.tech/xschem/sky130*/*.sym>)
{
  my $symname=""; $symname=$1 if($fn=~m/\/([^\/]*)\.sym$/);
  print FH "#\n";
  print FH "# $symname\n";
  print FH "#\n";
  print FH "DEF $symname U 0 20 Y N 1 F N\n";
  open IN,"<$fn";
  my %dir=();
  my %dirmap=("in"=>"I","out"=>"O","inout"=>"B");
  while(<IN>)
  {
    $dir{$1}=$dirmap{$2} if(m/name=(\w+) dir=(\w+)/);
  }
  close IN;
  print FH "F0 \"SC\" -350 500 50 H V C CNN\n";
  print FH "F1 \"$symname\" 400 500 50 H V R CNN\n";
  print FH "F2 \"\" 0 -1500 50 H I C CNN\n";
  print FH "F3 \"\" 0 0 50 H I C CNN\n";
  print FH "DRAW\n";
  $defaultpinnumber = 1; # Pin number for components as not all components have pin numbers
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
      #print FH "X $text $text $x1 $y1 200 U 50 50 1 0 I\n";
      print FH "T 0 $x1 $y1 50 0 0 0 $text Normal 0 C C\n";
            #T 0 0   150 50 0 0 0 2x    Normal 0 C C
      $nT++;
    }
    if(m/^B (\d+) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) \{(.*)\}/) # Rectangle
    {
      my ($data)=($6);
      my @pairs = split(/\s+/,$data);
      my %hash = map { split(/=/, $_, 2) } @pairs;
      $xname="~";
      $xdir="U";
      $xpinnumber="";
      $xgoto="";
      $xpropag="";
      $xorientation="";
      if ($hash{name}) { $xname=$hash{name}; }       
      if ($hash{dir}) { 
        if ($hash{dir} eq "in") { $xdir="I"; $xorientation="R"; }
        if ($hash{dir} eq "out") { $xdir="O", $xorientation="L"; }
      }       
      if ($hash{goto}) { $xgoto=($hash{goto}); }       
      if ($hash{propag}) { $xpropag=($hash{propag}); }       
      if ($hash{pinnumber}) { $xpinnumber=($hash{pinnumber}); }       
      my ($x,$y)=(int((($2+$4)/2)*10),int((($3+$5)/2)*10),$6);
      # X name num x y length UDRL sizeNum sizeName unit convert Etype shape
      print FH "X $xname $defaultpinnumber $x $y 10 $xorientation 40 40 0 0 $xdir \n";
      $defaultpinnumber++;
    }
    if(m/^L (\d+) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) \{(.*)\}/) # L Line
    {
      my($num,$x1,$y1,$x2,$y2,$data)=($1,int($2*10),int($3*-10),int($4*10),int($5*-10),$6);
      print FH "P 2 0 0 5 $x1 $y1 $x2 $y2 N\n";
    }
    if(m/^A (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) \{(.*)\}/) # A Arc
    {
      my($lay,$x1,$y1,$rad,$sa,$pa)=($1,int($2*10),int($3*-10),int($4*10),int($5*10),int($6*10));
      my $ea=$sa+$pa;
      if($ea>3600)
      {
        print FH "A $x1 $y1 $rad $sa 3600 0 0 1 N $x1 $y1 $x1 $y1\n";
        print FH "A $x1 $y1 $rad 0 ".($ea-3600)." 0 0 1 N $x1 $y1 $x1 $y1\n";
      }
      else
      {      
        print FH "A $x1 $y1 $rad $sa $ea 0 0 1 N $x1 $y1 $x1 $y1\n";
      }
    }



  }
  close IN;
  print FH "ENDDRAW\n";
  print FH "ENDDEF\n";
  print FH "#\n";
  print FH "#End Library\n";
}
close(FH);
