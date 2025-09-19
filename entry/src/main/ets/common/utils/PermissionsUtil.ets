import { abilityAccessCtrl, bundleManager, common, PermissionRequestResult, Permissions } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit';
import { JSON } from '@kit.ArkTS';

const context = getContext(this) as common.UIAbilityContext;
const TAG = "PermissionsUtil"

export class PermissionsUtil {
  // 检查是否授权
  static checkAccessToken(permission: Permissions): abilityAccessCtrl.GrantStatus {
    const atManager = abilityAccessCtrl.createAtManager();
    let grantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;
    let tokenId: number = 0;
    try {
      const bundleInfo = bundleManager
        .getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      const appInfo = bundleInfo.appInfo;
      tokenId = appInfo.accessTokenId;
      grantStatus = atManager.checkAccessTokenSync(tokenId, permission);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`${TAG} checkAccessToken Failed. Cause: ${JSON.stringify(err)}`);
    }
    return grantStatus;
  }

  // 动态申请权限
  static async reqPermissionsFromUser(permissions: Permissions[]): Promise<number[]> {
    console.info(`${TAG} reqPermissionsFromUser start.`);
    const atManager = abilityAccessCtrl.createAtManager();
    let result: PermissionRequestResult = { permissions: [], authResults: [] };
    try {
      result = await atManager.requestPermissionsFromUser(context, permissions);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`${TAG} reqPermissionsFromUser Failed. Cause: ${JSON.stringify(err)}`);
    }
    return result.authResults;
  }
}