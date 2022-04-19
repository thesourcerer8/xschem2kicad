#!/usr/bin/perl -w
use strict;
use POSIX qw/ceil/;

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
  my $namepos="-350 500";
  my $modelpos="400 500";
  while(<IN>)
  {
    $dir{$1}=$dirmap{$2} if(m/name=(\w+) dir=(\w+)/);
    if(m/^T \{\@name\} (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) \{([\^}]*)\}/) # Text
    {
      $namepos=int($1*10)." ".int($2*-10);
    }
    if(m/^T \{\@(symname|model)\} (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) \{([\^}]*)\}/) # Text
    {
      $modelpos=int($2*10)." ".int($3*-10);
    }
  }
  close IN;
  print FH "F0 \"SC\" $namepos 50 H V C CNN\n";
  print FH "F1 \"$symname\" $modelpos 50 H V R CNN\n";
  print FH "F2 \"\" 0 -1500 50 H I C CNN\n";
  print FH "F3 \"\" 0 0 50 H I C CNN\n";
  print FH "DRAW\n";
  open IN,"<$fn";
  my $nT=1;
  my $count=1;
  while(<IN>)
  { 
    if(m/^T \{([^\}]*)\} (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) \{([\^}]*)\}/) # Text
    {
      my ($text,$x1,$y1,$rot,$mirr)=($1,int($2*10),int($3*-10),int($4*10),int($5*10));
      next if($text=~m/^@/);
      $text=~s/>//;$text=~s/ //;
      $text="~" if($text eq "");
      $text="\"$text\"" if($text!~m/^\w+$/);
      #print FH "X $text $text $x1 $y1 200 U 50 50 1 0 I\n";
      print FH "T 0 $x1 $y1 50 0 0 0 $text Normal 0 C C\n";
            #T 0 0   150 50 0 0 0 2x    Normal 0 C C
      $nT++;
    }
    # if(m/^B (\d+) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) \{(.*)\}/) # Rectangle
    if(m/^B (\d+) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) \{(name=?\w*) (dir=?\w*)/) # Pins
    { 
      my($num,$x1,$y1,$name,$data)=($1,ceil($2/5)*50,ceil($3/5)*-50,$6,$7);
      $name =~ s/name=//;

      if(index($data, "dir=inout") != -1){
      print FH "X $name $count $x1 $y1 5 R 50 43 1 1 B\n";
      }
      elsif(index($data, "dir=in") != -1){
        $x1=$x1-100;
        print FH "X $name $count $x1 $y1 100 R  50 43 1 1 I\n";
      }
      else
      { $x1=$x1+100;
        print FH "X $name $count $x1 $y1 100 L 50 43 1 1 O\n";
      }
      $count++;    
    }
    if(m/^L (\d+) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) \{(.*)\}/) # L Line
    {
      my($num,$x1,$y1,$x2,$y2,$data)=($1,int($2*10),int($3*-10),int($4*10),int($5*-10),$6);
      print FH "P 2 0 0 2 $x1 $y1 $x2 $y2 N\n";
    }
    if(m/^A (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) (-?\d+\.?\d*) \{(.*)\}/) # A Arc
    {
      my($lay,$x1,$y1,$rad,$sa,$pa)=($1,int($2*10),int($3*-10),int($4*10),int($5*10),int($6*10));
      my $ea=$sa+$pa;
      if($ea>3600) # It goes around the end of the circle, so we split both the first and the second part up in 3 segments each
      {
        my $s1=int($sa+(3600-$sa)/3);
        my $s2=int($sa+(3600-$sa)*2/3);	
        print FH "A $x1 $y1 $rad $sa $s1 0 0 1 N\n";
        print FH "A $x1 $y1 $rad $s1 $s2 0 0 1 N\n";
        print FH "A $x1 $y1 $rad $s2 3600 0 0 1 N\n";
        my $s3=int(0+($ea-3600)/3);
        my $s4=int(0+($ea-3600)*2/3);	
        print FH "A $x1 $y1 $rad 0 $s3 0 0 1 N\n";
        print FH "A $x1 $y1 $rad $s3 $s4 0 0 1 N\n";
        print FH "A $x1 $y1 $rad $s4 ".($ea-3600)." 0 0 1 N\n";
      }
      elsif($pa<1800) # KiCad can draw it in one go
      {      
        print FH "A $x1 $y1 $rad $sa $ea 0 0 1 N\n";
      }
      else # We have to split it up in 3 segments for KiCad
      {
        my $s1=int($sa+$pa/3);
        my $s2=int($sa+$pa*2/3);	
        print FH "A $x1 $y1 $rad $sa $s1 0 0 1 N\n";
        print FH "A $x1 $y1 $rad $s1 $s2 0 0 1 N\n";
        print FH "A $x1 $y1 $rad $s2 $ea 0 0 1 N\n";
      }
    }
    if(m/^P (\d+) (\d+) (.*?) \{(.*)\}/) # P Polygon
    {
      my($lay,$np,$points,$param)=($1,$2,$3,$4);
      my @points=split(" ",$points);
      print FH "P $np 0 0 1 ";
      my $dir=1;
      foreach(@points)
      {
        print FH int($_*10*$dir)." ";
        $dir=-$dir;
      }
      print FH "".(($param=~m/fill=true/)?"F":"N")."\n";
    }

  }
  close IN;
  print FH "ENDDRAW\n";
  print FH "ENDDEF\n";
  print FH "#\n";
  print FH "#End Library\n";
}
close(FH);
