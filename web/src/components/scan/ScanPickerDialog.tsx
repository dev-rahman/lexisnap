import { useRef } from "react";
import { useNavigate } from "react-router-dom";
import { Camera, ImageIcon } from "lucide-react";

import { Sheet } from "@/components/ui/Sheet";
import { useT } from "@/providers/I18nProvider";
import { useAppDispatch, useAppSelector } from "@/store/hooks";
import { resetScan, setImage } from "@/store/slices/scanSlice";
import { closeScanPicker } from "@/store/slices/shellSlice";

/** Quick picker dialog for starting a scan — take a photo or choose from the
 *  gallery. Once an image is picked it seeds the scan flow and opens /scan at
 *  the review step, so there's no full-page image-picker screen. */
export function ScanPickerDialog() {
  const t = useT();
  const navigate = useNavigate();
  const dispatch = useAppDispatch();
  const open = useAppSelector((s) => s.shell.scanPickerOpen);
  const cameraRef = useRef<HTMLInputElement>(null);
  const galleryRef = useRef<HTMLInputElement>(null);

  function onPicked(file?: File) {
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => {
      dispatch(resetScan());
      dispatch(setImage(reader.result as string)); // → stage "reviewing"
      dispatch(closeScanPicker());
      navigate("/scan");
    };
    reader.readAsDataURL(file);
  }

  return (
    <Sheet open={open} onClose={() => dispatch(closeScanPicker())} title={t("scan_source_title")}>
      <p className="mb-5 text-[15px] text-ink-muted">{t("scan_source_subtitle")}</p>
      <div className="grid grid-cols-2 gap-3">
        <button
          onClick={() => cameraRef.current?.click()}
          className="flex flex-col items-center gap-3 rounded-2xl border border-border bg-card p-6 text-center transition-colors hover:border-coral/50 hover:bg-coral-soft/40"
        >
          <span className="grid h-14 w-14 place-items-center rounded-2xl bg-coral-soft text-coral">
            <Camera size={26} />
          </span>
          <span className="font-display font-bold text-ink">{t("scan_take_photo")}</span>
        </button>
        <button
          onClick={() => galleryRef.current?.click()}
          className="flex flex-col items-center gap-3 rounded-2xl border border-border bg-card p-6 text-center transition-colors hover:border-coral/50 hover:bg-coral-soft/40"
        >
          <span className="grid h-14 w-14 place-items-center rounded-2xl bg-hue-violet/12 text-hue-violet">
            <ImageIcon size={26} />
          </span>
          <span className="font-display font-bold text-ink">{t("scan_choose_from_gallery")}</span>
        </button>
      </div>

      <input
        ref={cameraRef}
        type="file"
        accept="image/*"
        capture="environment"
        className="hidden"
        onChange={(e) => onPicked(e.target.files?.[0])}
      />
      <input
        ref={galleryRef}
        type="file"
        accept="image/*"
        className="hidden"
        onChange={(e) => onPicked(e.target.files?.[0])}
      />
    </Sheet>
  );
}
