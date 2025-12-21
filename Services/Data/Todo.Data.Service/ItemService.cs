using System;
using System.Collections.Generic;
using System.Text;
using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Todo.Data.Access;
using C = Todo.Data.Entity.Context;
using E = Todo.Data.Entity;

namespace Todo.Data.Service;

// Filtering by Clipboard ID is a good idea if this were a production level app
public class ItemService(IMapper mapper)
{
    private readonly Guid demoUserID = new Guid("52515368-4ad4-4bae-9319-6886c234ee5a");

    public async Task<IList<Item>> GetItems(C context, int clipboardId, Guid userID)
    {
        var clipboard = await context.Clipboards
            .AsNoTracking()
            .SingleOrDefaultAsync(c => c.ID == clipboardId);

        if (clipboard == null)
        {
            throw new ArgumentException("Clipboard not found.");
        }
        else if(clipboard.UserID == userID || clipboard.UserID == demoUserID)
        {
            return await context.Items
            .Where(i => i.ClipboardID == clipboardId)
            .Select(i => mapper.Map<Item>(i))
            .ToListAsync();
        }

        throw new UnauthorizedAccessException("You do not have access to this clipboard.");
    }

    public async Task<Item> AddItem(C context, string name, int clipboardId, Guid userID)
    {
        var item = await context.Clipboards.Join(context.Items,
            cID => cID.ID,
            iID => iID.ClipboardID,
            (c, i) => new { Clipboard = c, Item = i })
            .SingleOrDefaultAsync(s => s.Item.Name == name && s.Clipboard.ID == clipboardId && s.Clipboard.UserID == userID);

        if (item != null)
        {
            throw new ArgumentException("Item already exists or you do not have permission to add items to this clipboard.");
        }

        var entity = new E.Item { ClipboardID = clipboardId, Name = name };
        await context.Items.AddAsync(entity);
        await context.SaveChangesAsync();

        var addedEntity = await context.Items
            .AsNoTracking()
            .SingleAsync(i => i.Name == name);

        return mapper.Map<Item>(addedEntity);
    }

    public async Task<Item> DeleteItem(C context, int itemID, Guid userID)
    {
        var item = await context.Clipboards.Join(context.Items,
            cID => cID.ID,
            iID => iID.ClipboardID,
            (c, i) => new { Clipboard = c, Item = i })
            .Where(c => c.Clipboard.UserID == userID && c.Item.ID == itemID)
            .Select(c => c.Item)
            .SingleOrDefaultAsync();

        if (item == null)
        {
            throw new ArgumentException("Item not found or you do not have permission to delete this item.");
        }

        context.Items.Remove(item);
        await context.SaveChangesAsync();
        return mapper.Map<Item>(item);
    }

    public async Task<Item> CompleteItem(C context, int itemID, Guid userID)
    {
        var item = await context.Clipboards.Join(context.Items,
            cID => cID.ID,
            iID => iID.ClipboardID,
            (c, i) => new { Clipboard = c, Item = i })
            .Where(c => c.Clipboard.UserID == userID && c.Item.ID == itemID)
            .Select(c => c.Item)
            .SingleOrDefaultAsync();

        if (item == null)
        {
            throw new ArgumentException("Item not found or you do not have permission to delete this item.");
        }

        item.IsComplete = true;
        await context.SaveChangesAsync();
        return mapper.Map<Item>(item);
    }

    public async Task<Item> UnfinishItem(C context, int itemID, Guid userID)
    {
        var item = await context.Clipboards.Join(context.Items,
            cID => cID.ID,
            iID => iID.ClipboardID,
            (c, i) => new { Clipboard = c, Item = i })
            .Where(c => c.Clipboard.UserID == userID && c.Item.ID == itemID)
            .Select(c => c.Item)
            .SingleOrDefaultAsync();

        if (item == null)
        {
            throw new ArgumentException("Item not found or you do not have permission to delete this item.");
        }

        item.IsComplete = false;
        await context.SaveChangesAsync();
        return mapper.Map<Item>(item);
    }

    public async Task<Item> EditItem(C context, int itemID, string name, Guid userID)
    {
        var item = await context.Clipboards.Join(context.Items,
            cID => cID.ID,
            iID => iID.ClipboardID,
            (c, i) => new { Clipboard = c, Item = i })
            .Where(c => c.Clipboard.UserID == userID && c.Item.ID == itemID)
            .Select(c => c.Item)
            .SingleOrDefaultAsync();

        if (item == null)
        {
            throw new ArgumentException("Item not found or you do not have permission to delete this item.");
        }

        item.Name = name;
        await context.SaveChangesAsync();
        return mapper.Map<Item>(item);
    }
}
