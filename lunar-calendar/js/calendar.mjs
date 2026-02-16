import { getDateInfo } from "./module/date.mjs";
import { getTimestampBySolar } from "./module/solar.mjs";
import { getTimestampByLunar } from "./module/lunar.mjs";

export function getDateBySolar(sYear, sMonth, sDay) {
    let timestamp = getTimestampBySolar(sYear, sMonth, sDay);
    return timestamp ? getDateInfo(timestamp) : null;
}

export function getDateByLunar(lYear, lMonth, lDay, isLeap) {
    let timestamp = getTimestampByLunar(lYear, lMonth, lDay, isLeap);
    return timestamp ? getDateInfo(timestamp) : null;
}

export function getDateByTimestamp(timestamp) {
    return getDateInfo(timestamp);
}

export function getToday() {
    return getDateInfo(Date.now());
}
