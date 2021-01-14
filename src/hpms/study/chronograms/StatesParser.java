package hpms.study.chronograms;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Properties;
import java.util.SortedMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class StatesParser {

   static void parse( File statesPath, SortedMap<String, Samples> allSamples ) throws IOException {
      final Map<String, Map<String, Integer>> enums = new HashMap<>();
      final Properties types = new Properties();
      try( BufferedReader br = new BufferedReader( new FileReader( statesPath.getPath() + ".properties"))) {
         types.load( br );
         final String enumList = types.getProperty( "enums" );
         if( enumList != null ) {
            for( final String enm : enumList.split( "," )) {
               final String name = enm.trim();
               final String def  = types.getProperty( name );
               final Map<String, Integer> enumDef = new LinkedHashMap<>();
               for( final String nvpair : def.split( "," )) {
                  final String[] nv  = nvpair.split( ":" );
                  if( nv.length != 2 ) {
                     throw new IllegalStateException(
                        "Enum " + name + ": syntax error, must be a list of <literal name>:<integer value>" );
                  }
                  final String   lit = nv[0];
                  final int      val = Integer.parseInt( nv[1] );
                  enumDef.put( lit, val );
               }
               enums.put( name, enumDef );
            }
         }
      }
      try( BufferedReader br = new BufferedReader( new FileReader( statesPath ) )) {
         String line;
         final Pattern separator = Pattern.compile( "% -- ([1-9][0-9\\.]+) --" );
         Samples._first = -1.0;
         while(( line = br.readLine()) != null ) {
            if( ! line.startsWith( "% " )) {
               break;
            }
            final Matcher m = separator.matcher( line );
            if( m.matches()) {
               Samples._last = Double.parseDouble( m.group( 1 ));
               if( Samples._first < 0.0 ) {
                  Samples._first = Samples._last;
               }
               continue;
            }
            final String[] assignments = line.substring( 2 ).split( ";" );
            for( final String assignment : assignments ) {
               final String[] parts = assignment.trim().split( ":" );
               if( parts.length != 2 ) {
                  throw new IllegalStateException( "Log syntax error: ':' expected in " + line );
               }
               final String name  = parts[0].trim();
               final String value = parts[1].trim();
               if( value.charAt( 0 ) != '_' ) {
                  Samples samples = allSamples.get( name );
                  if( samples == null ) {
                     final Type type;
                     if( enums.containsKey( name )) {
                        type = Type.INTEGER;
                     }
                     else {
                        final String typeName = types.getProperty( name );
                        if( typeName == null ) {
                           throw new IllegalStateException( "Variable inconnue : " + name );
                        }
                        if( enums.containsKey( typeName )) {
                           type = Type.INTEGER;
                        }
                        else {
                           type = Type.valueOf( typeName );
                        }
                     }
                     allSamples.put( name, samples = new Samples( name, type ));
                  }
                  samples.addSample( Samples._last, value );
               }
            }
         }
         for( final String chrono : types.getProperty( "chronograms" ).split( "," )) {
            final Samples samples = allSamples.get( chrono.trim());
            if( samples != null ) {
               samples._displayed.set( true );
            }
         }
         for( final Samples samples : allSamples.values()) {
            samples.compact();
         }
         Samples._last = 0.0;
         for( final Samples samples : allSamples.values()) {
            if( samples._displayed.get()) {
               Samples._last = Math.max( Samples._last, samples._values.get( samples._values.size() - 1 )._timestamp );
            }
         }
         Samples._last += (Samples._last - Samples._first)*0.02; // On ajoute 2 % de temps
         for( final Samples samples : allSamples.values()) {
            if( samples._displayed.get()) {
               final Sample last = samples._values.get( samples._values.size() - 1 );
               samples._values.add( new Sample( Samples._last, last._value ));
            }
         }
      }
   }
}
