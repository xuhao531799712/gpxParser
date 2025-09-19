import { geoLocationManager } from "@kit.LocationKit";
import { BusinessError } from "@kit.BasicServicesKit";


export class LocationUtil {

  static TAG = 'LocationUtil'

  static async currentLocation(): Promise<geoLocationManager.Location | undefined> {
    const request: geoLocationManager.SingleLocationRequest = {
      'locatingPriority': geoLocationManager.LocatingPriority.PRIORITY_LOCATING_SPEED,
      'locatingTimeoutMs': 10000
    }
    let location: geoLocationManager.Location | undefined = undefined
    try {
      location = await geoLocationManager.getCurrentLocation(request)
      console.log(`${LocationUtil.TAG} getLastLocation succeeded. Data: ${JSON.stringify(location)}`);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`${LocationUtil.TAG} getLastLocation failed. Cause: ${JSON.stringify(err)}`);
    }
    return location;
  }

}