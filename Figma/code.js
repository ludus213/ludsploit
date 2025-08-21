figma.showUI(__html__, { width: 320, height: 470 });

const imageAssetMap = new Map();

figma.ui.onmessage = async (msg) => {
  if (msg.type === 'export') {
    imageAssetMap.clear();
    const selection = figma.currentPage.selection;
    if (selection.length === 0) {
      figma.notify("Please select at least one frame or component.");
      figma.ui.postMessage({ type: 'export-result', mappingString: '', images: [] });
      return;
    }

    let referenceSize = { x: 0, y: 0 };
    if (selection.length === 1 && selection[0].parent.type !== "PAGE") {
        referenceSize = { x: selection[0].parent.width, y: selection[0].parent.height };
    } else {
        let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
        selection.forEach(node => {
            minX = Math.min(minX, node.x);
            minY = Math.min(minY, node.y);
            maxX = Math.max(maxX, node.x + node.width);
            maxY = Math.max(maxY, node.y + node.height);
        });
        referenceSize = { x: maxX - minX, y: maxY - minY };
    }

    const mapping = [];
    for (const node of selection) {
      mapping.push(await processNode(node, imageAssetMap));
    }

    const exportData = {
        referenceSize: referenceSize,
        nodes: mapping
    };

    const mappingString = JSON.stringify(exportData, null, 2);
    const images = Array.from(imageAssetMap.entries()).map(([id, bytes]) => ({ id, bytes }));
    figma.ui.postMessage({ type: 'export-result', mappingString: mappingString, images: images });
  }
};

const RASTERIZE_TYPES = new Set(['VECTOR', 'ELLIPSE', 'POLYGON', 'STAR', 'LINE']);

async function processNode(node, assetMap) {
  const tags = parseTags(node.name);
  const assetId = parseAssetId(node.name);

  const nodeData = {
    id: node.id,
    name: node.name,
    type: node.type,
    tags: tags,
    properties: getNodeProperties(node),
    children: [],
    assetId: null,
  };

  const hasMask = node.children && node.children.some(child => child.isMask);
  const hasBlurEffect = node.effects && node.effects.some(effect => effect.type === 'LAYER_BLUR' && effect.visible);
  const shouldRasterize = RASTERIZE_TYPES.has(node.type);

  const isExportable = tags.includes('image') || tags.includes('button') || tags.includes('parent') || hasBlurEffect || hasMask || shouldRasterize;

  if (isExportable) {
      if (assetId) {
        nodeData.assetId = assetId;
        if (!assetMap.has(assetId)) {
          const imageBytes = await node.exportAsync({ format: 'PNG', constraint: { type: 'SCALE', value: 2 } });
          assetMap.set(assetId, imageBytes);
        }
      } else {
        const autoAssetId = `asset_${node.id.replace(/:/g, '_')}`;
        nodeData.assetId = autoAssetId;
        if (!assetMap.has(autoAssetId)) {
            const imageBytes = await node.exportAsync({ format: 'PNG', constraint: { type: 'SCALE', value: 2 } });
            assetMap.set(autoAssetId, imageBytes);
        }
      }
      if (hasMask || shouldRasterize) {
          return nodeData;
      }
  }

  if (tags.includes('parent')) {
    return nodeData;
  }

  if ('children'in node) {
    for (const child of node.children) {
        if (!child.isMask) {
            nodeData.children.push(await processNode(child, assetMap));
        }
    }
  }

  return nodeData;
}

function parseTags(name) {
    const nameWithoutId = name.split('#')[0];
    return nameWithoutId.split('_').slice(1).filter(t => t);
}

function parseAssetId(name) {
    const match = name.match(/#(\w+)/);
    return match ? match[1] : null;
}

function getNodeProperties(node) {
  const properties = {
    size: { x: node.width, y: node.height },
    position: { x: node.x, y: node.y },
    rotation: node.rotation,
    opacity: node.opacity,
    visible: node.visible,
    effects: node.effects,
  };

  if ('fills' in node) properties.fills = node.fills;
  if ('strokes' in node) properties.strokes = node.strokes;
  if ('strokeWeight' in node) properties.strokeWeight = node.strokeWeight;
  if ('cornerRadius' in node) properties.cornerRadius = node.cornerRadius;
  if ('constraints' in node) properties.constraints = node.constraints;

  if (node.type === 'TEXT') {
    properties.characters = node.characters;
    properties.fontSize = node.fontSize;
    properties.fontName = node.fontName;
    properties.textAlignHorizontal = node.textAlignHorizontal;
    properties.textAlignVertical = node.textAlignVertical;
    properties.lineHeight = node.lineHeight;
    properties.letterSpacing = node.letterSpacing;
    properties.textCase = node.textCase;
    properties.textDecoration = node.textDecoration;
  }

  return properties;
}
