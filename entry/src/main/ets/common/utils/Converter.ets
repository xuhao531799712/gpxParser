import { GeoJSONWriter } from "../roadFileUtils/geoJSON/GeoJSONWriter"
import { GPXWriter } from "../roadFileUtils/gpx/GPXWriter"
import { KMLWriter } from "../roadFileUtils/kml/KMLWriter"
import { Parser } from "../roadFileUtils/RoadTypes"
import { TCXWriter } from "../roadFileUtils/tcx/TCXWriter"
import { CommonUtils } from "./CommonUtils"

export class Converter {

  static TAG = 'Converter'
  static parser: Parser | undefined = undefined

  static async convertContent(content: string, sourceFormat:string, targetFormat: string, targetPath: string): Promise<Error | null> {
    try {
      Converter.parser = CommonUtils.createParser(sourceFormat)
      await Converter.parseAsync(content)
      switch (targetFormat) {
        case 'gpx':
          await GPXWriter.writeGPXFile(Converter.parser.tracks, Converter.parser.waypoints, targetPath)
          break;
        case 'kml':
          await KMLWriter.writeKMLFile(Converter.parser.tracks, Converter.parser.waypoints, targetPath)
          break;
        case 'tcx':
          await TCXWriter.writeTCXFile(Converter.parser.tracks, targetPath)
          break;
        case 'geojson':
          await GeoJSONWriter.writeGeoJSONFile(Converter.parser.tracks, Converter.parser.waypoints, targetPath)
          break;
      }
      return null
    } catch (e) {
      return e
    }
  }

  private static parseAsync(contentString: string): Promise<void> {
    return new Promise((resolve, reject) => {
      Converter.parser!.parse(contentString, (error?: Error) => {
        if (error) {
          reject(error);
        } else {
          resolve();
        }
      });
    });
  }


}