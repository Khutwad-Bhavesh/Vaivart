import 'package:path/path.dart' as p;

enum JobStatus { waiting, converting, done, failed }

class ConversionJob {
  final String sourcePath;
  final String fileName;
  final String extension;
  final String fileSize;
  final String? targetFormat;
  final JobStatus status;

  const ConversionJob({
    required this.sourcePath,
    required this.fileName,
    required this.extension,
    required this.fileSize,
    this.targetFormat,
    this.status = JobStatus.waiting,
  });

  factory ConversionJob.fromFile(String path) {
    final name = p.basename(path);
    final ext = p.extension(path).replaceAll('.', '').toUpperCase();
    final job = ConversionJob(
      sourcePath: path,
      fileName: name,
      extension: ext,
      fileSize: '',
    );
    return job.copyWith(targetFormat: job.availableFormats.isNotEmpty ? job.availableFormats.first : null);
  }

  ConversionJob copyWith({String? targetFormat, JobStatus? status}) {
    return ConversionJob(
      sourcePath: sourcePath,
      fileName: fileName,
      extension: extension,
      fileSize: fileSize,
      targetFormat: targetFormat ?? this.targetFormat,
      status: status ?? this.status,
    );
  }

List<String> get availableFormats {
  switch (extension.toLowerCase()) {
    // ── Images ──
    case 'jpg':
    case 'jpeg': return ['PNG', 'WEBP', 'BMP', 'TIFF', 'GIF', 'TGA', 'ICO', 'PDF'];
    case 'png': return ['JPG', 'WEBP', 'BMP', 'TIFF', 'GIF', 'TGA', 'ICO', 'PDF'];
    case 'webp': return ['JPG', 'PNG', 'BMP', 'TIFF', 'TGA', 'PDF'];
    case 'bmp': return ['JPG', 'PNG', 'WEBP', 'TIFF', 'TGA', 'PDF'];
    case 'tiff':
    case 'tif': return ['JPG', 'PNG', 'WEBP', 'BMP', 'TGA', 'PDF'];
    case 'gif': return ['JPG', 'PNG', 'WEBP', 'BMP', 'TIFF', 'TGA'];
    case 'ico': return ['PNG', 'JPG', 'BMP', 'TGA'];
    case 'heic': return ['JPG', 'PNG', 'WEBP', 'BMP'];
    case 'svg': return ['PNG', 'JPG', 'PDF'];
    case 'tga': return ['PNG', 'JPG', 'BMP', 'TIFF', 'WEBP'];
    case 'psd': return ['PNG', 'JPG', 'BMP', 'TIFF', 'WEBP', 'TGA'];
    case 'pnm':
    case 'pbm':
    case 'pgm':
    case 'ppm': return ['PNG', 'JPG', 'BMP', 'TIFF', 'WEBP', 'TGA'];
    case 'exr': return ['PNG', 'JPG', 'BMP', 'TIFF', 'WEBP', 'TGA'];
    case 'pvr': return ['PNG', 'JPG', 'BMP', 'TIFF'];
    case 'cur': return ['PNG', 'JPG', 'BMP'];

    // ── Video ──
    case 'mp4': return ['AVI', 'MKV', 'WEBM', 'MOV', 'FLV', 'WMV', '3GP', 'VOB', 'TS', 'GIF', 'MP3'];
    case 'avi': return ['MP4', 'MKV', 'WEBM', 'MOV', 'FLV', 'WMV', '3GP', 'VOB', 'TS', 'GIF', 'MP3'];
    case 'mkv': return ['MP4', 'AVI', 'WEBM', 'MOV', 'FLV', 'WMV', '3GP', 'VOB', 'TS', 'GIF', 'MP3'];
    case 'mov': return ['MP4', 'AVI', 'MKV', 'WEBM', 'FLV', 'WMV', '3GP', 'VOB', 'TS', 'GIF', 'MP3'];
    case 'webm': return ['MP4', 'AVI', 'MKV', 'MOV', 'FLV', 'WMV', '3GP', 'VOB', 'TS', 'GIF', 'MP3'];
    case 'flv': return ['MP4', 'AVI', 'MKV', 'WEBM', 'MOV', 'WMV', '3GP', 'VOB', 'TS', 'GIF', 'MP3'];
    case 'wmv': return ['MP4', 'AVI', 'MKV', 'WEBM', 'MOV', 'FLV', '3GP', 'VOB', 'TS', 'GIF', 'MP3'];
    case '3gp': return ['MP4', 'AVI', 'MKV', 'WEBM', 'MOV', 'FLV', 'WMV', 'VOB', 'TS', 'GIF', 'MP3'];
    case 'vob': return ['MP4', 'AVI', 'MKV', 'WEBM', 'MOV', 'FLV', 'WMV', '3GP', 'TS', 'GIF', 'MP3'];
    case 'mts':
    case 'm2ts': return ['MP4', 'AVI', 'MKV', 'WEBM', 'MOV', 'FLV', 'WMV', 'GIF', 'MP3'];
    case 'ts': return ['MP4', 'AVI', 'MKV', 'WEBM', 'MOV', 'FLV', 'WMV', 'GIF', 'MP3'];
    case 'divx': return ['MP4', 'AVI', 'MKV', 'WEBM', 'MOV', 'FLV', 'WMV', 'GIF', 'MP3'];
    case 'asf': return ['MP4', 'AVI', 'MKV', 'WEBM', 'MOV', 'FLV', 'WMV', 'GIF', 'MP3'];

    // ── Audio ──
    case 'mp3': return ['WAV', 'OGG', 'FLAC', 'AAC', 'M4A', 'WMA', 'AIFF', 'OPUS', 'AC3', 'AU'];
    case 'wav': return ['MP3', 'OGG', 'FLAC', 'AAC', 'M4A', 'WMA', 'AIFF', 'OPUS', 'AC3', 'AU'];
    case 'ogg': return ['MP3', 'WAV', 'FLAC', 'AAC', 'M4A', 'WMA', 'AIFF', 'OPUS', 'AC3', 'AU'];
    case 'flac': return ['MP3', 'WAV', 'OGG', 'AAC', 'M4A', 'WMA', 'AIFF', 'OPUS', 'AC3', 'AU'];
    case 'aac': return ['MP3', 'WAV', 'OGG', 'FLAC', 'M4A', 'WMA', 'AIFF', 'OPUS', 'AC3', 'AU'];
    case 'm4a': return ['MP3', 'WAV', 'OGG', 'FLAC', 'AAC', 'WMA', 'AIFF', 'OPUS', 'AC3', 'AU'];
    case 'wma': return ['MP3', 'WAV', 'OGG', 'FLAC', 'AAC', 'M4A', 'AIFF', 'OPUS', 'AC3', 'AU'];
    case 'aiff': return ['MP3', 'WAV', 'OGG', 'FLAC', 'AAC', 'M4A', 'WMA', 'OPUS', 'AC3', 'AU'];
    case 'opus': return ['MP3', 'WAV', 'OGG', 'FLAC', 'AAC', 'M4A', 'WMA', 'AIFF', 'AC3', 'AU'];
    case 'amr': return ['MP3', 'WAV', 'OGG', 'FLAC', 'AAC', 'M4A', 'OPUS'];
    case 'ac3': return ['MP3', 'WAV', 'OGG', 'FLAC', 'AAC', 'M4A', 'WMA', 'AIFF', 'OPUS'];
    case 'au':
    case 'snd': return ['MP3', 'WAV', 'OGG', 'FLAC', 'AAC', 'M4A', 'OPUS'];
    case 'dts': return ['MP3', 'WAV', 'OGG', 'FLAC', 'AAC', 'M4A', 'AC3'];
    case 'ra':
    case 'ram': return ['MP3', 'WAV', 'OGG', 'FLAC', 'AAC'];

    // ── Documents ──
    case 'pdf': return ['DOCX', 'PNG', 'JPG'];
    case 'docx': case 'doc': return ['PDF'];
    case 'txt': return ['PDF'];
    case 'md':
    case 'markdown': return ['PDF'];
    case 'html':
    case 'htm': return ['PDF'];
    case 'rtf': return ['PDF'];
    case 'odt': return ['PDF'];
    case 'odp': return ['PDF'];
    case 'pptx':
    case 'ppt': return ['PDF'];
    case 'epub': return ['PDF'];
    case 'xml': return ['PDF'];
    case 'json': return ['PDF', 'CSV'];
    case 'yaml':
    case 'yml': return ['PDF'];
    case 'log': return ['PDF'];
    case 'ps': return ['PDF'];
    case 'xps':
    case 'oxps': return ['PDF'];
    case 'djvu':
    case 'djv': return ['PDF'];

    // ── Data ──
    case 'csv': return ['XLSX', 'JSON', 'TSV', 'PDF'];
    case 'xlsx': return ['CSV', 'JSON'];
    case 'tsv': return ['CSV'];
    case 'ods': return ['CSV', 'XLSX'];

    default: return [];
  }
}
}